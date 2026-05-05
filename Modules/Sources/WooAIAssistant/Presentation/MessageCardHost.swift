import SwiftUI

struct MessageCardHost: View {

    let toolName: String
    let payload: AnyCodableJSON

    @Environment(\.assistantExternalViews) private var externalViews
    @Environment(\.assistantExternalNavigation) private var externalNavigation

    var body: some View {
        switch TypedCardDispatcher.route(for: toolName) {
        case .ordersList:
            orderCard(rows: EntityCardPayload.decodeOrderRows(payload), shape: .list)
        case .productsList:
            productCard(rows: EntityCardPayload.decodeProductRows(payload), shape: .list)
        case .productVariationsList:
            variationCard(rows: EntityCardPayload.decodeProductVariationRows(payload), shape: .list)
        case .customersList:
            customerCard(rows: EntityCardPayload.decodeCustomerRows(payload), shape: .list)
        case .analyticsStats:
            statsView
        case .order:
            orderCard(rows: EntityCardPayload.decodeOrder(payload).map { [$0] } ?? [], shape: .single)
        case .product:
            productCard(rows: EntityCardPayload.decodeProduct(payload).map { [$0] } ?? [], shape: .single)
        case .productVariation:
            variationCard(rows: EntityCardPayload.decodeProductVariation(payload).map { [$0] } ?? [], shape: .single)
        case .customer:
            customerCard(rows: EntityCardPayload.decodeCustomer(payload).map { [$0] } ?? [], shape: .single)
        case .unknown:
            RawJSONCard(toolName: toolName, payload: payload)
        }
    }

    private enum CardShape {
        case single
        case list
    }

    private func orderCard(rows: [OrderCardPayload], shape: CardShape) -> some View {
        EntityCard(
            title: Localization.ordersTitle,
            iconSystemName: "list.bullet.rectangle.portrait",
            payloads: rows,
            isEmpty: { $0.isEmpty },
            row: { row, showDivider in
                AnyView(externalViews.orderRow(payload: row, showDivider: showDivider, onTap: {
                    guard let id = row.id else { return }
                    externalNavigation.openOrder(orderID: id, payload: payloadForTap(row, shape: shape))
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private func productCard(rows: [ProductCardPayload], shape: CardShape) -> some View {
        EntityCard(
            title: Localization.productsTitle,
            iconSystemName: "tag",
            payloads: rows,
            isEmpty: { $0.isEmpty },
            row: { row, showDivider in
                AnyView(externalViews.productRow(payload: row, showDivider: showDivider, onTap: {
                    guard let id = row.id else { return }
                    externalNavigation.openProduct(productID: id, payload: payloadForTap(row, shape: shape))
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private func variationCard(rows: [ProductVariationCardPayload], shape: CardShape) -> some View {
        EntityCard(
            title: Localization.variationsTitle,
            iconSystemName: "square.grid.2x2",
            payloads: rows,
            isEmpty: { $0.isEmpty },
            row: { row, showDivider in
                AnyView(externalViews.productVariationRow(payload: row, showDivider: showDivider, onTap: {
                    guard let id = row.id,
                          let parentID = ProductVariationCardPayload.resolveParentID(row: row, parent: payload) else { return }
                    externalNavigation.openProductVariation(productID: parentID,
                                                            variationID: id,
                                                            payload: payloadForTap(row, shape: shape))
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private func customerCard(rows: [CustomerCardPayload], shape: CardShape) -> some View {
        EntityCard(
            title: Localization.customersTitle,
            iconSystemName: "person.2",
            payloads: rows,
            isEmpty: { $0.isEmpty },
            row: { row, showDivider in
                AnyView(externalViews.customerRow(payload: row, showDivider: showDivider, onTap: {
                    guard let id = row.id, id > 0 else { return }
                    externalNavigation.openCustomer(customerID: id, payload: payloadForTap(row, shape: shape))
                }) ?? AnyView(EmptyView()))
            }
        )
    }

    private func payloadForTap<T: Encodable>(_ row: T, shape: CardShape) -> AnyCodableJSON {
        if shape == .single { return payload }
        guard let data = try? JSONEncoder().encode(row),
              let encoded = try? JSONDecoder().decode(AnyCodableJSON.self, from: data) else {
            return .object([:])
        }
        return encoded
    }

    @ViewBuilder
    private var statsView: some View {
        if let host = externalViews.statsCardView(toolName: toolName, payload: payload) {
            Button(action: { externalNavigation.openAnalyticsHub(payload: payload) }) {
                host
            }
            .buttonStyle(AssistantPressableButtonStyle())
        } else {
            RawJSONCard(toolName: toolName, payload: payload)
        }
    }

    private enum Localization {
        static let ordersTitle = NSLocalizedString(
            "assistantCard.order.listTitle",
            value: "Orders",
            comment: "Title for the orders assistant card. Always plural even for a single order."
        )
        static let productsTitle = NSLocalizedString(
            "assistantCard.product.listTitle",
            value: "Products",
            comment: "Title for the products assistant card. Always plural even for a single product."
        )
        static let variationsTitle = NSLocalizedString(
            "assistantCard.productVariation.listTitle",
            value: "Variations",
            comment: "Title for the product variations assistant card. Mirrors the Products tab nav title."
        )
        static let customersTitle = NSLocalizedString(
            "assistantCard.customer.listTitle",
            value: "Customers",
            comment: "Title for the customers assistant card. Always plural even for a single customer."
        )
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
        let listPayload = AnyCodableJSON.object(["rows": .array(payloads)])
        switch family {
        case .order:
            MessageCardHost(toolName: OrdersListTool.name, payload: listPayload)
        case .product:
            MessageCardHost(toolName: ProductsListTool.name, payload: listPayload)
        case .productVariation:
            MessageCardHost(toolName: ProductVariationsListTool.name, payload: listPayload)
        case .customer:
            MessageCardHost(toolName: CustomersListTool.name, payload: listPayload)
        }
    }
}

enum TypedCardDispatcher {

    enum Route: Equatable {
        case ordersList
        case productsList
        case productVariationsList
        case customersList
        case analyticsStats
        case order
        case product
        case productVariation
        case customer
        case unknown
    }

    static func route(for toolName: String) -> Route {
        if toolName == OrdersListTool.name { return .ordersList }
        if toolName == ProductsListTool.name { return .productsList }
        if toolName == ProductVariationsListTool.name { return .productVariationsList }
        if toolName == CustomersListTool.name { return .customersList }
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
