import Foundation
import Networking

/// Collection of static functions that creates specific products from a `fake` instance.
///
public enum ProductFactory {

    /// Returns a fake product with a 3 downloadable files
    ///
    public static func productWithDownloadableFiles() -> Product {
        Product.fake().copy(
            downloadable: true,
            downloads: [
                ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b11", name: "Song #1", fileURL: "https://example.com/woo-single-1.ogg"),
                ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b12", name: "Song #2", fileURL: "https://example.com/woo-single-2.ogg"),
                ProductDownload(downloadID: "1f9c11f99ceba63d4403c03bd5391b13", name: "Song #3", fileURL: "https://example.com/woo-single-3.ogg")
            ],
            downloadLimit: 1,
            downloadExpiry: 1
        )
    }

    /// Returns a fake product filled with data can be edited by the merchants
    ///
    public static func productWithEditableDataFilled() -> Product {
        Product.fake().copy(name: "name",
                            dateOnSaleStart: Date(),
                            dateOnSaleEnd: Date(),
                            fullDescription: "description",
                            shortDescription: "short description",
                            regularPrice: "10.0",
                            salePrice: "5.0",
                            downloadable: true,
                            downloadLimit: 100,
                            downloadExpiry: 200,
                            taxStatusKey: ProductTaxStatus.taxable.rawValue,
                            taxClass: "standard",
                            manageStock: true,
                            stockQuantity: 50.0,
                            stockStatusKey: ProductStockStatus.inStock.rawValue,
                            backordersKey: ProductBackordersSetting.allowed.rawValue,
                            soldIndividually: true,
                            weight: "3.0",
                            dimensions: ProductDimensions.fake(),
                            shippingClass: "standard",
                            shippingClassID: 123,
                            categories: [.fake()],
                            tags: [.fake()])
    }
}
