import Foundation
@testable import Networking


final class MockProduct {
    func product(siteID: Int64 = 2019,
                 productID: Int64 = 2020,
                 dateCreated: Date = Date(),
                 downloadable: Bool = false,
                 name: String = "Hogsmeade",
                 productStatus: ProductStatus = .publish,
                 productType: ProductType = .simple,
                 sku: String? = nil,
                 stockQuantity: Int? = nil,
                 stockStatus: ProductStockStatus = .inStock,
                 variations: [Int64] = [],
                 virtual: Bool = true,
                 images: [ProductImage] = [],
                 shippingClassID: Int64 = 0,
                 categories: [ProductCategory] = []) -> Product {

        return Product(siteID: siteID,
                       productID: productID,
                       name: name,
                       slug: "book-the-green-room",
                       permalink: "https://example.com/product/book-the-green-room/",
                       dateCreated: dateCreated,
                       dateModified: Date(),
                       dateOnSaleStart: date(with: "2019-10-15T21:30:00"),
                       dateOnSaleEnd: date(with: "2019-10-27T21:29:59"),
                       productTypeKey: productType.rawValue,
                       statusKey: productStatus.rawValue,
                       featured: false,
                       catalogVisibilityKey: "visible",
                       fullDescription: "<p>This is the party room!</p>\n",
                       briefDescription: """
                       [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                       We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let us \
                       know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests \
                       for $100.</p>\n
                       """,
                       sku: sku,
                       price: "0",
                       regularPrice: "",
                       salePrice: "",
                       onSale: false,
                       purchasable: true,
                       totalSales: 0,
                       virtual: virtual,
                       downloadable: downloadable,
                       downloads: [],
                       downloadLimit: -1,
                       downloadExpiry: -1,
                       externalURL: "http://somewhere.com",
                       taxStatusKey: "taxable",
                       taxClass: "standard",
                       manageStock: false,
                       stockQuantity: stockQuantity,
                       stockStatusKey: stockStatus.rawValue,
                       backordersKey: "no",
                       backordersAllowed: false,
                       backordered: false,
                       soldIndividually: true,
                       weight: "213",
                       // Since the dimensions are not included in `update(with:)` in `ReadOnlyConvertible`, set them to empty here so that they are the same
                       // as the default value.
                       dimensions: ProductDimensions(length: "", width: "", height: ""),
                       shippingRequired: false,
                       shippingTaxable: false,
                       shippingClass: "",
                       shippingClassID: shippingClassID,
                       productShippingClass: nil,
                       reviewsAllowed: true,
                       averageRating: "4.30",
                       ratingCount: 23,
                       relatedIDs: [31, 22, 369, 414, 56],
                       upsellIDs: [99, 1234566],
                       crossSellIDs: [1234, 234234, 3],
                       parentID: 0,
                       purchaseNote: "Thank you!",
                       categories: categories,
                       tags: [],
                       images: images,
                       attributes: [],
                       defaultAttributes: [],
                       variations: variations,
                       groupedProducts: [],
                       menuOrder: 0)

    }

    private func date(with dateString: String) -> Date {
        guard let date = DateFormatter.Defaults.dateTimeFormatter.date(from: dateString) else {
            return Date()
        }
        return date
    }
}
