import Foundation

public enum POSParentProductType {
    case variable
}

public struct POSParentProduct: Equatable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let productImageSource: String?
    public let productID: Int64
    public let type: POSParentProductType

    public init(id: UUID, name: String, productImageSource: String?, productID: Int64, type: POSParentProductType) {
        self.id = id
        self.name = name
        self.productImageSource = productImageSource
        self.productID = productID
        self.type = type
    }
}
