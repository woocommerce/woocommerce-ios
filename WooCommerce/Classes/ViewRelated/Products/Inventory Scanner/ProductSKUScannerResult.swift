import Foundation

enum ProductSKUScannerResult {
    case matched(product: ProductFormDataModel)
    case noMatch(sku: String)
}

extension ProductSKUScannerResult: Equatable {
    static func ==(lhs: ProductSKUScannerResult, rhs: ProductSKUScannerResult) -> Bool {
        switch (lhs, rhs) {
        case (let .matched(product1), let .matched(product2)):
            if let product1 = product1 as? EditableProductModel, let product2 = product2 as? EditableProductModel {
                return product1 == product2
            } else if let product1 = product1 as? EditableProductVariationModel, let product2 = product2 as? EditableProductVariationModel {
                return product1 == product2
            } else {
                return false
            }
        case (let .noMatch(sku1), let .noMatch(sku2)):
            return sku1 == sku2
        default:
            return false
        }
    }
}
