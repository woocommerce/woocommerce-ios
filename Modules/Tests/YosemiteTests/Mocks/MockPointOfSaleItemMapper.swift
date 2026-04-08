import Foundation
@testable import Yosemite

final class MockPointOfSaleItemMapper: PointOfSaleItemMapperProtocol {
    var mapProductsToPOSItemsCalled = false
    var mapVariationsToPOSItemsCalled = false
    var mapProductToPOSItemCalled = false
    var mapVariationToSearchResultPOSItemCalled = false
    var mockProducts: [POSProduct] = []
    var mockVariations: [POSProductVariation] = []
    var mockParentProduct: POSVariableParentProduct?
    var mockMappedProducts: [POSItem] = []
    var mockMappedVariations: [POSItem] = []
    var mockMappedProduct: POSItem?
    var mockMappedSearchResultVariation: POSItem?

    func mapProductsToPOSItems(products: [POSProduct]) -> [POSItem] {
        mapProductsToPOSItemsCalled = true
        mockProducts = products
        return mockMappedProducts
    }

    func mapVariationsToPOSItems(variations: [POSProductVariation], parentProduct: POSVariableParentProduct) -> [POSItem] {
        mapVariationsToPOSItemsCalled = true
        mockVariations = variations
        mockParentProduct = parentProduct
        return mockMappedVariations
    }

    func mapProductToPOSItem(product: POSProduct) -> POSItem? {
        mapProductToPOSItemCalled = true
        mockProducts = [product]
        return mockMappedProduct
    }

    func mapVariationToSearchResultPOSItem(variation: POSProductVariation, parentProduct: POSProduct) -> POSItem? {
        mapVariationToSearchResultPOSItemCalled = true
        mockVariations = [variation]
        return mockMappedSearchResultVariation
    }
}
