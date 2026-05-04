import Foundation
import CocoaLumberjackSwift

public struct DefaultConfirmationSnapshotResolver: ConfirmationSnapshotResolving {

    private let client: WCRESTClient

    public init(client: WCRESTClient) {
        self.client = client
    }

    public func resolve(toolName: String, arguments: String) async -> ConfirmationSnapshot? {
        switch toolName {
        case OrdersUpdateTool.name:
            return await resolveOrder(arguments: arguments)
        case ProductsUpdateTool.name:
            return await resolveProduct(arguments: arguments)
        case ProductVariationsUpdateTool.name:
            return await resolveVariation(arguments: arguments)
        default:
            return nil
        }
    }

    private func resolveOrder(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable { let id: Int? }
        guard let parsed = decode(Args.self, from: arguments), let id = parsed.id else {
            return nil
        }
        struct OrderResponse: Decodable { let status: String? }
        guard let order = await fetch(OrderResponse.self, path: "wc/v3/orders/\(id)") else {
            return nil
        }
        var values: [String: ConfirmationPreviewText] = [:]
        if let status = order.status {
            values["status"] = .raw(Self.normalizeOrderStatus(status))
        }
        return values.isEmpty ? nil : ConfirmationSnapshot(currentValues: values)
    }

    private func resolveProduct(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable { let id: Int? }
        guard let parsed = decode(Args.self, from: arguments), let id = parsed.id else {
            return nil
        }
        struct ProductResponse: Decodable {
            let name: String?
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Double?
            let status: String?
        }
        guard let product = await fetch(ProductResponse.self, path: "wc/v3/products/\(id)") else {
            return nil
        }
        var values: [String: ConfirmationPreviewText] = [:]
        if let name = product.name { values["name"] = .raw(name) }
        if let price = product.regular_price { values["regular_price"] = .raw(price) }
        if let sale = product.sale_price { values["sale_price"] = .raw(sale) }
        if let quantity = product.stock_quantity {
            values["stock_quantity"] = .raw(Self.formatStockQuantity(quantity))
        }
        if let status = product.status { values["status"] = .raw(status) }
        return values.isEmpty ? nil : ConfirmationSnapshot(currentValues: values)
    }

    private func resolveVariation(arguments: String) async -> ConfirmationSnapshot? {
        struct Args: Decodable {
            let product_id: Int?
            let id: Int?
        }
        guard let parsed = decode(Args.self, from: arguments),
              let productID = parsed.product_id, let variationID = parsed.id else {
            return nil
        }
        struct VariationResponse: Decodable {
            let regular_price: String?
            let sale_price: String?
            let stock_quantity: Double?
            let stock_status: String?
            let sku: String?
            let status: String?
        }
        let path = "wc/v3/products/\(productID)/variations/\(variationID)"
        guard let variation = await fetch(VariationResponse.self, path: path) else {
            return nil
        }
        var values: [String: ConfirmationPreviewText] = [:]
        if let price = variation.regular_price { values["regular_price"] = .raw(price) }
        if let sale = variation.sale_price { values["sale_price"] = .raw(sale) }
        if let quantity = variation.stock_quantity {
            values["stock_quantity"] = .raw(Self.formatStockQuantity(quantity))
        }
        if let stockStatus = variation.stock_status { values["stock_status"] = .raw(stockStatus) }
        if let sku = variation.sku { values["sku"] = .raw(sku) }
        if let status = variation.status { values["status"] = .raw(status) }
        return values.isEmpty ? nil : ConfirmationSnapshot(currentValues: values)
    }

    private func fetch<T: Decodable>(_ type: T.Type, path: String) async -> T? {
        let response = await client.request(method: "GET", path: path, query: nil, body: nil)
        guard (200..<300).contains(response.statusCode) else {
            DDLogError("DefaultConfirmationSnapshotResolver fetch \(path) returned HTTP \(response.statusCode)")
            return nil
        }
        do {
            return try JSONDecoder().decode(type, from: response.data)
        } catch {
            DDLogError("DefaultConfirmationSnapshotResolver decode \(type) failed: \(error)")
            return nil
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            DDLogError("DefaultConfirmationSnapshotResolver args decode \(type) failed: \(error)")
            return nil
        }
    }

    static func normalizeOrderStatus(_ raw: String) -> String {
        raw.hasPrefix("wc-") ? String(raw.dropFirst(3)) : raw
    }

    static func formatStockQuantity(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1.0) == 0 {
            return String(Int(value))
        }
        return String(value)
    }
}
