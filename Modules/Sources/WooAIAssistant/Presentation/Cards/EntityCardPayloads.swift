import Foundation

public let entityCardVisibleRowLimit = 10
public let entityCardDefaultRowCount = 5

public enum EntityCardPayload {

    public static func decodeOrder(_ payload: AnyCodableJSON) -> OrderCardPayload? {
        decode(payload)
    }

    public static func decodeProduct(_ payload: AnyCodableJSON) -> ProductCardPayload? {
        decode(payload)
    }

    public static func decodeCustomer(_ payload: AnyCodableJSON) -> CustomerCardPayload? {
        decode(payload)
    }

    public static func decodeProductVariation(_ payload: AnyCodableJSON) -> ProductVariationCardPayload? {
        decode(payload)
    }

    private static func decode<T: Decodable>(_ value: AnyCodableJSON) -> T? {
        do {
            let data = try JSONEncoder().encode(value)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Order

public struct OrderCardPayload: Codable, Equatable, Sendable {
    public let id: Int64?
    public let number: String?
    public let status: String?
    public let total: String?
    public let currency: String?
    public let dateCreated: String?
    public let customerName: String?
    public let customerEmail: String?
    public let customerID: Int64?
    public let parentID: Int64?

    public init(id: Int64? = nil,
                number: String? = nil,
                status: String? = nil,
                total: String? = nil,
                currency: String? = nil,
                dateCreated: String? = nil,
                customerName: String? = nil,
                customerEmail: String? = nil,
                customerID: Int64? = nil,
                parentID: Int64? = nil) {
        self.id = id
        self.number = number
        self.status = status
        self.total = total
        self.currency = currency
        self.dateCreated = dateCreated
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.customerID = customerID
        self.parentID = parentID
    }

    enum CodingKeys: String, CodingKey {
        case id, number, status, total, currency
        case dateCreated = "date_created"
        case customerName = "customer_name"
        case customerEmail = "customer_email"
        case customerID = "customer_id"
        case parentID = "parent_id"
    }

    public var isEmpty: Bool {
        id == nil && number == nil && total == nil && customerName == nil
    }
}

// MARK: - Product

public struct ProductCardPayload: Codable, Equatable, Sendable {
    public let id: Int64?
    public let name: String?
    public let sku: String?
    public let price: String?
    public let regularPrice: String?
    public let salePrice: String?
    public let stockStatus: String?
    public let stockQuantity: Double?
    public let type: String?
    public let status: String?
    public let images: [Image]?
    public let variationsCount: Int?

    public struct Image: Codable, Equatable, Sendable {
        public let src: String?
    }

    public init(id: Int64? = nil,
                name: String? = nil,
                sku: String? = nil,
                price: String? = nil,
                regularPrice: String? = nil,
                salePrice: String? = nil,
                stockStatus: String? = nil,
                stockQuantity: Double? = nil,
                type: String? = nil,
                status: String? = nil,
                images: [Image]? = nil,
                variationsCount: Int? = nil) {
        self.id = id
        self.name = name
        self.sku = sku
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.stockStatus = stockStatus
        self.stockQuantity = stockQuantity
        self.type = type
        self.status = status
        self.images = images
        self.variationsCount = variationsCount
    }

    enum CodingKeys: String, CodingKey {
        case id, name, sku, price, type, status, images
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case stockStatus = "stock_status"
        case stockQuantity = "stock_quantity"
        case variationsCount = "variations_count"
    }

    public var isEmpty: Bool {
        id == nil && (name?.isEmpty ?? true)
    }

    public var firstImageURL: URL? {
        guard let raw = images?.compactMap(\.src).first(where: { !$0.isEmpty }) else { return nil }
        return URL(string: raw)
    }
}

// MARK: - Product variation

public struct ProductVariationCardPayload: Codable, Equatable, Sendable {
    public let id: Int64?
    public let parentID: Int64?
    public let name: String?
    public let sku: String?
    public let price: String?
    public let regularPrice: String?
    public let salePrice: String?
    public let stockStatus: String?
    public let stockQuantity: Double?
    public let image: ProductCardPayload.Image?

    public init(id: Int64? = nil,
                parentID: Int64? = nil,
                name: String? = nil,
                sku: String? = nil,
                price: String? = nil,
                regularPrice: String? = nil,
                salePrice: String? = nil,
                stockStatus: String? = nil,
                stockQuantity: Double? = nil,
                image: ProductCardPayload.Image? = nil) {
        self.id = id
        self.parentID = parentID
        self.name = name
        self.sku = sku
        self.price = price
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.stockStatus = stockStatus
        self.stockQuantity = stockQuantity
        self.image = image
    }

    enum CodingKeys: String, CodingKey {
        case id, name, sku, price, image
        case parentID = "parent_id"
        case regularPrice = "regular_price"
        case salePrice = "sale_price"
        case stockStatus = "stock_status"
        case stockQuantity = "stock_quantity"
    }

    public var isEmpty: Bool {
        id == nil && (name?.isEmpty ?? true)
    }

    public var firstImageURL: URL? {
        guard let raw = image?.src, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}

// MARK: - Customer

public struct CustomerCardPayload: Codable, Equatable, Sendable {
    public let id: Int64?
    public let firstName: String?
    public let lastName: String?
    public let name: String?
    public let username: String?
    public let email: String?
    public let ordersCount: Int?

    public init(id: Int64? = nil,
                firstName: String? = nil,
                lastName: String? = nil,
                name: String? = nil,
                username: String? = nil,
                email: String? = nil,
                ordersCount: Int? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.name = name
        self.username = username
        self.email = email
        self.ordersCount = ordersCount
    }

    enum CodingKeys: String, CodingKey {
        case id, name, username, email
        case firstName = "first_name"
        case lastName = "last_name"
        case ordersCount = "orders_count"
    }

    public var isEmpty: Bool {
        id == nil && (displayName?.isEmpty ?? true) && (email?.isEmpty ?? true)
    }

    public var displayName: String? {
        let combined = [firstName, lastName]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " ")
        if !combined.isEmpty { return combined }
        if let name, !name.isEmpty { return name }
        if let username, !username.isEmpty { return username }
        if let email, !email.isEmpty { return email }
        return nil
    }
}
