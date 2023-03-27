import UITestsFoundation
import XCTest

class ProductFlow {

    static func addAndVerifyNewProduct(productType: String) throws {
        let product = try GetMocks.readNewProductData()

        try TabNavComponent().goToProductsScreen()
            .selectAddProduct()
            .selectProductType(productType: productType)
            .verifyProductTypeScreenLoaded(productType: productType)
            .addProductTitle(productTitle: product.name)
            .publishProduct()
            .verifyNewProductScreenLoaded(productName: product.name)
    }
}
