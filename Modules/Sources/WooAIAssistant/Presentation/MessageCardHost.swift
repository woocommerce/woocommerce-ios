import SwiftUI

struct MessageCardHost: View {

    let toolName: String
    let payload: AnyCodableJSON

    var body: some View {
        switch TypedCardDispatcher.route(for: toolName) {
        case .analyticsStats:
            AnalyticsStatsCardSection(toolName: toolName, payload: payload)
        case .order:
            OrderCardSection(rows: EntityCardPayload.decodeOrder(payload).map { [EntityCardEntry(payload: $0, source: payload)] } ?? [])
        case .product:
            ProductCardSection(rows: EntityCardPayload.decodeProduct(payload).map { [EntityCardEntry(payload: $0, source: payload)] } ?? [])
        case .productVariation:
            ProductVariationCardSection(rows: EntityCardPayload.decodeProductVariation(payload)
                .map { [EntityCardEntry(payload: $0, source: payload)] } ?? [])
        case .customer:
            CustomerCardSection(rows: EntityCardPayload.decodeCustomer(payload).map { [EntityCardEntry(payload: $0, source: payload)] } ?? [])
        case .unknown:
            RawJSONCard(toolName: toolName, payload: payload)
        }
    }
}

private struct EntityCardEntry<Payload> {
    let payload: Payload
    let source: AnyCodableJSON
}

private struct OrderCardSection: View {

    let rows: [EntityCardEntry<OrderCardPayload>]

    @Environment(\.assistantExternalViews) private var externalViews
    @Environment(\.assistantExternalNavigation) private var externalNavigation

    var body: some View {
        EntityCard(
            title: Localization.title,
            iconSystemName: "list.bullet.rectangle.portrait",
            payloads: rows,
            isEmpty: { $0.payload.isEmpty },
            row: { entry, showDivider in
                AnyView(externalViews.orderRow(payload: entry.payload, showDivider: showDivider, onTap: {
                    guard let id = entry.payload.id else { return }
                    externalNavigation.openOrder(orderID: id, payload: entry.source)
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantCard.order.listTitle",
            value: "Orders",
            comment: "Title for the orders assistant card. Always plural even for a single order."
        )
    }
}

private struct ProductCardSection: View {

    let rows: [EntityCardEntry<ProductCardPayload>]

    @Environment(\.assistantExternalViews) private var externalViews
    @Environment(\.assistantExternalNavigation) private var externalNavigation

    var body: some View {
        EntityCard(
            title: Localization.title,
            iconSystemName: "tag",
            payloads: rows,
            isEmpty: { $0.payload.isEmpty },
            row: { entry, showDivider in
                AnyView(externalViews.productRow(payload: entry.payload, showDivider: showDivider, onTap: {
                    guard let id = entry.payload.id else { return }
                    externalNavigation.openProduct(productID: id, payload: entry.source)
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantCard.product.listTitle",
            value: "Products",
            comment: "Title for the products assistant card. Always plural even for a single product."
        )
    }
}

private struct ProductVariationCardSection: View {

    let rows: [EntityCardEntry<ProductVariationCardPayload>]

    @Environment(\.assistantExternalViews) private var externalViews
    @Environment(\.assistantExternalNavigation) private var externalNavigation

    var body: some View {
        EntityCard(
            title: Localization.title,
            iconSystemName: "square.grid.2x2",
            payloads: rows,
            isEmpty: { $0.payload.isEmpty },
            row: { entry, showDivider in
                AnyView(externalViews.productVariationRow(payload: entry.payload, showDivider: showDivider, onTap: {
                    guard let id = entry.payload.id,
                          let parentID = ProductVariationCardPayload.resolveParentID(row: entry.payload, parent: entry.source) else { return }
                    externalNavigation.openProductVariation(productID: parentID,
                                                            variationID: id,
                                                            payload: entry.source)
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantCard.productVariation.listTitle",
            value: "Variations",
            comment: "Title for the product variations assistant card. Mirrors the Products tab nav title."
        )
    }
}

private struct CustomerCardSection: View {

    let rows: [EntityCardEntry<CustomerCardPayload>]

    @Environment(\.assistantExternalViews) private var externalViews
    @Environment(\.assistantExternalNavigation) private var externalNavigation

    var body: some View {
        EntityCard(
            title: Localization.title,
            iconSystemName: "person.2",
            payloads: rows,
            isEmpty: { $0.payload.isEmpty },
            row: { entry, showDivider in
                AnyView(externalViews.customerRow(payload: entry.payload, showDivider: showDivider, onTap: {
                    guard let id = entry.payload.id, id > 0 else { return }
                    externalNavigation.openCustomer(customerID: id, payload: entry.source)
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private enum Localization {
        static let title = NSLocalizedString(
            "assistantCard.customer.listTitle",
            value: "Customers",
            comment: "Title for the customers assistant card. Always plural even for a single customer."
        )
    }
}

private struct AnalyticsStatsCardSection: View {

    let toolName: String
    let payload: AnyCodableJSON

    @Environment(\.assistantExternalViews) private var externalViews
    @Environment(\.assistantExternalNavigation) private var externalNavigation

    var body: some View {
        if let host = externalViews.statsCardView(toolName: toolName, payload: payload) {
            Button(action: { externalNavigation.openAnalyticsHub(payload: payload) }) {
                host
            }
            .buttonStyle(AssistantPressableButtonStyle())
        } else {
            RawJSONCard(toolName: toolName, payload: payload)
        }
    }
}

extension ProductVariationCardPayload {

    // ProductSummary.make drops parent_id from variation rows; outer list payload carries product_id.
    static func resolveParentID(row: ProductVariationCardPayload, parent: AnyCodableJSON) -> Int64? {
        if let parentID = row.parentID { return parentID }
        guard case .object(let dict) = parent, let value = dict["product_id"] else { return nil }
        switch value {
        case .int(let int): return int
        case .double(let double): return Int64(double)
        case .string(let string): return Int64(string)
        default: return nil
        }
    }
}

struct MessageCardListHost: View {

    let family: MessageSegmentGrouping.CardRunFamily
    let payloads: [AnyCodableJSON]

    var body: some View {
        switch family {
        case .order:
            OrderCardSection(rows: payloads.compactMap { source in
                EntityCardPayload.decodeOrder(source).map { EntityCardEntry(payload: $0, source: source) }
            })
        case .product:
            ProductCardSection(rows: payloads.compactMap { source in
                EntityCardPayload.decodeProduct(source).map { EntityCardEntry(payload: $0, source: source) }
            })
        case .productVariation:
            ProductVariationCardSection(rows: payloads.compactMap { source in
                EntityCardPayload.decodeProductVariation(source).map { EntityCardEntry(payload: $0, source: source) }
            })
        case .customer:
            CustomerCardSection(rows: payloads.compactMap { source in
                EntityCardPayload.decodeCustomer(source).map { EntityCardEntry(payload: $0, source: source) }
            })
        }
    }
}

enum TypedCardDispatcher {

    enum Route: Equatable {
        case analyticsStats
        case order
        case product
        case productVariation
        case customer
        case unknown
    }

    static func route(for toolName: String) -> Route {
        if toolName == AnalyticsRevenueTool.name || toolName == AnalyticsOrdersTool.name { return .analyticsStats }

        let parts = toolName.split(separator: ".")
        guard parts.count >= 2 else { return .unknown }
        let family = String(parts.last ?? "")

        switch family {
        case "order":
            return .order
        case "product":
            return .product
        case "product_variation":
            return .productVariation
        case "customer":
            return .customer
        default:
            return .unknown
        }
    }
}

#if DEBUG
#Preview("Fallback to JSON") {
    MessageCardHost(toolName: "unknown_tool",
                    payload: MockAssistantController.sampleOrderListPayload())
        .padding()
}

#Preview("In chat") {
    AssistantChatView.preview(.textPlusCard)
}
#endif
