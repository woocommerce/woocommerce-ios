import CocoaLumberjackSwift
import Foundation
import Storage
import Yosemite

@MainActor
final class OrderCardProvider: CardEntityProvider {

    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let dispatchAction: @Sendable (Action) -> Void

    init(siteID: Int64,
         storageManager: StorageManagerType,
         dispatchAction: @escaping @Sendable (Action) -> Void) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.dispatchAction = dispatchAction
    }

    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome] {
        guard refs.isEmpty == false else { return [:] }

        var outcomes: [CardRef: CardEntityOutcome] = [:]
        var misses: [CardRef] = []
        for ref in refs {
            if let order = storageManager.viewStorage.loadOrder(siteID: siteID, orderID: ref.id)?.toReadOnly() {
                outcomes[ref] = outcome(for: order)
            } else {
                misses.append(ref)
            }
        }

        guard misses.isEmpty == false else { return outcomes }

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<[Yosemite.Order], Error>, Never>) in
            let action = OrderAction.retrieveOrders(siteID: siteID, orderIDs: misses.map { $0.id }) { result in
                continuation.resume(returning: result)
            }
            dispatchAction(action)
        }

        switch result {
        case .success:
            for ref in misses {
                if let order = storageManager.viewStorage.loadOrder(siteID: siteID, orderID: ref.id)?.toReadOnly() {
                    outcomes[ref] = outcome(for: order)
                } else {
                    outcomes[ref] = .rejected(.notFound)
                }
            }
        case .failure(let error):
            DDLogError("OrderCardProvider remote fetch failed: \(error)")
            for ref in misses {
                outcomes[ref] = .rejected(.fetchFailed)
            }
        }
        return outcomes
    }

    private static let iso8601Formatter = ISO8601DateFormatter()

    private func outcome(for order: Yosemite.Order) -> CardEntityOutcome {
        if order.status.rawValue == "trash" {
            return .rejected(.staleReference)
        }
        let billing = order.billingAddress
        let firstName = billing?.firstName ?? ""
        let lastName = billing?.lastName ?? ""
        let combined = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        let payload = OrderCardPayload(
            id: order.orderID,
            number: order.number,
            status: order.status.rawValue,
            total: order.total,
            currency: order.currency,
            dateCreated: Self.iso8601Formatter.string(from: order.dateCreated),
            customerName: combined.isEmpty ? nil : combined,
            customerEmail: billing?.email,
            // Yosemite uses 0 as a sentinel for absent customer/parent; the payload expects nil.
            customerID: order.customerID > 0 ? order.customerID : nil,
            parentID: order.parentID > 0 ? order.parentID : nil
        )
        return .found(.order(payload))
    }
}
