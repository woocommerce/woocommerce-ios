import Foundation

public struct POSVariation: Equatable, Hashable, Identifiable {
    // Identifiable
    public let id: UUID

    public let name: String
    public let formattedPrice: String
    public var productImageSource: String?

    public init(id: UUID, name: String, formattedPrice: String, productImageSource: String? = nil) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.productImageSource = productImageSource
    }
}
