import Foundation
import Yosemite

enum CardEntityPayloadFactory {
    private static let iso8601Formatter = ISO8601DateFormatter()

    static func payload(from order: Yosemite.Order) -> OrderCardPayload {
        let billing = order.billingAddress
        let firstName = billing?.firstName ?? ""
        let lastName = billing?.lastName ?? ""
        let combined = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return OrderCardPayload(
            id: order.orderID,
            number: order.number,
            status: order.status.rawValue,
            total: order.total,
            currency: order.currency,
            dateCreated: Self.iso8601Formatter.string(from: order.dateCreated),
            customerName: combined.isEmpty ? nil : combined,
            customerEmail: billing?.email,
            customerID: order.customerID > 0 ? order.customerID : nil,
            parentID: order.parentID > 0 ? order.parentID : nil
        )
    }

    static func payload(from product: Yosemite.Product) -> ProductCardPayload {
        ProductCardPayload(
            id: product.productID,
            name: product.name,
            sku: product.sku,
            price: product.price,
            regularPrice: product.regularPrice,
            salePrice: product.salePrice,
            stockStatus: product.stockStatusKey,
            stockQuantity: product.stockQuantity.map { NSDecimalNumber(decimal: $0).doubleValue },
            type: product.productTypeKey,
            status: product.statusKey,
            images: product.images.map { ProductCardPayload.Image(src: $0.src) }
        )
    }

    static func payload(from variation: Yosemite.ProductVariation, parentID: Int64? = nil) -> ProductVariationCardPayload {
        ProductVariationCardPayload(
            id: variation.productVariationID,
            parentID: parentID ?? variation.productID,
            name: variationDisplayName(from: variation.attributes),
            sku: variation.sku,
            price: variation.price,
            regularPrice: variation.regularPrice,
            salePrice: variation.salePrice,
            stockStatus: variation.stockStatus.rawValue,
            stockQuantity: variation.stockQuantity.map { NSDecimalNumber(decimal: $0).doubleValue },
            images: variation.image.map { [ProductCardPayload.Image(src: $0.src)] }
        )
    }

    static func json<T: Encodable>(from payload: T) -> AnyCodableJSON? {
        do {
            let data = try JSONEncoder().encode(payload)
            return try JSONDecoder().decode(AnyCodableJSON.self, from: data)
        } catch {
            return nil
        }
    }

    static func json(from entity: CardEntity) -> AnyCodableJSON? {
        switch entity {
        case .order(let payload):
            return json(from: payload)
        case .product(let payload):
            return json(from: payload)
        case .variation(let payload):
            return json(from: payload)
        case .customer(let payload):
            return json(from: payload)
        case .analyticsStats(let payload):
            return payload
        }
    }

    private static func variationDisplayName(from attributes: [ProductVariationAttribute]) -> String? {
        let joined = attributes.map(\.option).filter { $0.isEmpty == false }.joined(separator: ", ")
        return joined.isEmpty ? nil : joined
    }
}
