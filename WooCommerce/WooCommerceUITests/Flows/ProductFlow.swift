import UITestsFoundation
import XCTest

class ProductFlow {

    static func addAndVerifyNewProduct(productType: String) throws {
        let product = try GetMocks.readNewProductData(productType: productType)

        try TabNavComponent().goToProductsScreen()
            .tapAddProduct()
            .tapProductType(productType: productType)
            .verifyProductTypeScreenLoaded(productType: productType)
            .addProductTitle(productTitle: product.name)
            .publishProduct()
            .verifyPublishedProductScreenLoaded(productType: productType, productName: product.name)
    }
}
