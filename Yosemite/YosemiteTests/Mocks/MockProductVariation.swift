import Foundation
@testable import Yosemite

final class MockProductVariation {
    func productVariation(siteID: Int64 = 2019,
                          productID: Int64 = 2020,
                          variationID: Int64 = 2783) -> ProductVariation {
        return ProductVariation(siteID: siteID,
                                productID: productID,
                                productVariationID: variationID,
                                attributes: [],
                                image: ProductImage(imageID: 2432,
                                                    dateCreated: dateFromGMT("2020-03-13T03:13:57"),
                                                    dateModified: dateFromGMT("2020-07-21T08:29:16"),
                                                    src: "",
                                                    name: "DSC_0010",
                                                    alt: ""),
                                permalink: "https://chocolate.com/marble",
                                dateCreated: dateFromGMT("2020-06-12T14:36:02"),
                                dateModified: dateFromGMT("2020-07-21T08:35:47"),
                                dateOnSaleStart: nil,
                                dateOnSaleEnd: nil,
                                status: .publish,
                                description: "<p>Nutty chocolate marble, 99% and organic.</p>\n",
                                sku: "87%-strawberry-marble",
                                price: "14.99",
                                regularPrice: "14.99",
                                salePrice: "",
                                onSale: false,
                                purchasable: true,
                                virtual: false,
                                downloadable: true,
                                downloads: [],
                                downloadLimit: -1,
                                downloadExpiry: 0,
                                taxStatusKey: "taxable",
                                taxClass: "",
                                manageStock: true,
                                stockQuantity: 16,
                                stockStatus: .inStock,
                                backordersKey: "notify",
                                backordersAllowed: true,
                                backordered: false,
                                weight: "2.5",
                                dimensions: ProductDimensions(length: "10",
                                                              width: "2.5",
                                                              height: ""),
                                shippingClass: "",
                                shippingClassID: 0,
                                menuOrder: 1)

    }

    private func dateFromGMT(_ dateStringInGMT: String) -> Date {
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        return dateFormatter.date(from: dateStringInGMT)!
    }
}
