import Foundation

public struct POSVariableParentProduct: Equatable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let productImageSource: String?
    public let productID: Int64
    let allAttributes: [ProductAttribute]

    init(id: UUID, name: String, productImageSource: String?, productID: Int64, allAttributes: [ProductAttribute]) {
        self.id = id
        self.name = name
        self.productImageSource = productImageSource
        self.productID = productID
        self.allAttributes = allAttributes
    }

    #if DEBUG

    /// Initializer for SwiftUI previews.
    public init(id: UUID, name: String, productImageSource: String?, productID: Int64) {
        self.init(id: id, name: name, productImageSource: productImageSource, productID: productID, allAttributes: [])
    }

    #endif
}
