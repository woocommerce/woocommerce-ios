import CocoaLumberjackSwift
import Foundation
import Storage
import Yosemite

struct OrderUpdatePatch: Sendable {
    let status: String?
    let customerNote: String?
    let billingEmail: String?

    var hasAnyField: Bool {
        status != nil || customerNote != nil || billingEmail != nil
    }

    var fields: [OrderUpdateField] {
        var fields: [OrderUpdateField] = []
        if status != nil { fields.append(.status) }
        if customerNote != nil { fields.append(.customerNote) }
        if billingEmail != nil { fields.append(.billingAddress) }
        return fields
    }
}

@MainActor
protocol AssistantOrdersDataSourceProtocol: Sendable {
    func updateOrder(id: Int64, patch: OrderUpdatePatch) async -> Result<Yosemite.Order, Error>
    func bulkUpdateOrders(ids: [Int64], patch: OrderUpdatePatch) async -> Result<BulkWriteResult, Error>
}

@MainActor
final class AssistantOrdersDataSource: AssistantOrdersDataSourceProtocol, CardEntityDataSource {
    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let dispatcher: StoreActionDispatcher

    init(siteID: Int64,
         storageManager: StorageManagerType,
         dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.dispatcher = StoreActionDispatcher(dispatchAction: dispatchAction)
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        let lookup = await orders(ids: refs.map(\.id))
        let ordersByID = lookup.items.reduce(into: [Int64: Yosemite.Order]()) { keyed, order in
            keyed[order.orderID] = order
        }
        var outcomes: [CardRef: CardEntityOutcome] = [:]
        for ref in refs {
            if let order = ordersByID[ref.id] {
                outcomes[ref] = outcome(for: order)
            } else {
                outcomes[ref] = .rejected(lookup.fetchFailed ? .fetchFailed : .notFound)
            }
        }
        return outcomes
    }

    func updateOrder(id: Int64, patch: OrderUpdatePatch) async -> Result<Yosemite.Order, Error> {
        let existing = patch.billingEmail == nil ? await order(id: id) : await freshOrder(id: id)
        guard case .success(let order) = existing else {
            if case .failure(let error) = existing {
                return .failure(error)
            }
            return .failure(AssistantDataSourceError.notFound("Order #\(id) was not found"))
        }

        return await dispatcher.dispatch { completion in
            OrderAction.updateOrder(siteID: self.siteID,
                                    order: order.applying(patch),
                                    giftCard: nil,
                                    fields: patch.fields,
                                    onCompletion: completion)
        }
    }

    func bulkUpdateOrders(ids: [Int64], patch: OrderUpdatePatch) async -> Result<BulkWriteResult, Error> {
        let fetchedOrders: [Yosemite.Order]
        if patch.billingEmail == nil {
            let lookup = await orders(ids: ids)
            if let fetchError = lookup.fetchError {
                return .failure(fetchError)
            }
            fetchedOrders = lookup.items
        } else {
            let refreshResult = await freshOrders(ids: ids)
            guard case .success(let orders) = refreshResult else {
                if case .failure(let error) = refreshResult {
                    return .failure(error)
                }
                return .failure(AssistantDataSourceError.notFound("Orders could not be refreshed before update"))
            }
            fetchedOrders = orders
        }

        let ordersByID = fetchedOrders.reduce(into: [Int64: Yosemite.Order]()) { keyed, order in
            keyed[order.orderID] = order
        }
        var updatedIDs: [Int64] = []
        var failedItems = ids
            .filter { ordersByID[$0] == nil }
            .map { BulkWriteResult.FailedItem(id: $0, message: "Order #\($0) was not found") }

        for id in ids {
            guard let order = ordersByID[id] else { continue }
            let result = await dispatcher.dispatch { completion in
                OrderAction.updateOrder(siteID: self.siteID,
                                        order: order.applying(patch),
                                        giftCard: nil,
                                        fields: patch.fields,
                                        onCompletion: completion)
            }
            switch result {
            case .success(let order):
                updatedIDs.append(order.orderID)
            case .failure(let error):
                if WriteOutcomeClassifier.isOutcomeUnknown(error) {
                    return .failure(error)
                }
                failedItems.append(.init(id: id, message: error.localizedDescription))
            }
        }
        return .success(BulkWriteResult(updatedIDs: updatedIDs, failedItems: failedItems))
    }

    private func order(id: Int64) async -> Result<Yosemite.Order, Error> {
        if let stored = storageManager.viewStorage.loadOrder(siteID: siteID, orderID: id)?.toReadOnly() {
            return .success(stored)
        }
        let lookup = await orders(ids: [id])
        if let order = lookup.items.first(where: { $0.orderID == id }) {
            return .success(order)
        }
        return .failure(AssistantDataSourceError.notFound("Order #\(id) was not found"))
    }

    private func freshOrder(id: Int64) async -> Result<Yosemite.Order, Error> {
        await dispatcher.dispatch { completion in
            OrderAction.retrieveOrderRemotely(siteID: self.siteID, orderID: id, onCompletion: completion)
        }
    }

    private func freshOrders(ids: [Int64]) async -> Result<[Yosemite.Order], Error> {
        await dispatcher.dispatch { completion in
            OrderAction.retrieveOrders(siteID: self.siteID, orderIDs: ids, onCompletion: completion)
        }
    }

    private func orders(ids: [Int64]) async -> CachedEntityLookup<Yosemite.Order> {
        let ids = Array(Set(ids))
        guard ids.isEmpty == false else {
            return CachedEntityLookup(items: [])
        }

        var cached: [Yosemite.Order] = []
        var missingIDs: [Int64] = []
        for id in ids {
            if let order = storageManager.viewStorage.loadOrder(siteID: siteID, orderID: id)?.toReadOnly() {
                cached.append(order)
            } else {
                missingIDs.append(id)
            }
        }
        guard missingIDs.isEmpty == false else {
            return CachedEntityLookup(items: cached)
        }

        let result: Result<[Yosemite.Order], Error> = await dispatcher.dispatch { completion in
            OrderAction.retrieveOrders(siteID: self.siteID, orderIDs: missingIDs, onCompletion: completion)
        }
        switch result {
        case .success(let fetched):
            return CachedEntityLookup(items: cached + fetched)
        case .failure(let error):
            DDLogError("AssistantOrdersDataSource remote fetch failed: \(error)")
            return CachedEntityLookup(items: cached, fetchError: error)
        }
    }

    private func outcome(for order: Yosemite.Order) -> CardEntityOutcome {
        if order.status.rawValue == "trash" {
            return .rejected(.staleReference)
        }
        return .found(.order(CardEntityPayloadFactory.payload(from: order)))
    }
}

private extension Yosemite.Order {
    func applying(_ patch: OrderUpdatePatch) -> Yosemite.Order {
        var updated = self
        if let status = patch.status {
            updated = updated.copy(status: OrderStatusEnum(rawValue: status))
        }
        if let note = patch.customerNote {
            updated = updated.copy(customerNote: note)
        }
        if let email = patch.billingEmail {
            let billing = (updated.billingAddress ?? Address.empty).copy(email: email)
            updated = updated.copy(billingAddress: billing)
        }
        return updated
    }
}
