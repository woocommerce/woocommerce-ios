import XCTest
@testable import Networking

/// Unit Tests for `ProductVariationMapper`
///
final class ProductVariationMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Dummy Product ID.
    ///
    private let dummyProductID: Int64 = 295

    /// Verifies that all of the ProductVariation Fields are parsed correctly.
    ///
    func testProductVariationFieldsAreProperlyParsed() throws {
        let productVariation = try XCTUnwrap(mapLoadProductVariationResponse())

        XCTAssertEqual(productVariation, sampleProductVariation(siteID: dummySiteID, productID: dummyProductID, id: 2783))
    }
}

/// Private Helpers
///
private extension ProductVariationMapperTests {
    /// Returns the ProductVariationMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductVariation(from filename: String) -> ProductVariation? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try? ProductVariationMapper(siteID: dummySiteID, productID: dummyProductID).map(response: response)
    }

    /// Returns the ProductVariationMapper output upon receiving `ProductVariation`
    ///
    func mapLoadProductVariationResponse() -> ProductVariation? {
        return mapProductVariation(from: "product-variation-update")
    }
}

private extension ProductVariationMapperTests {
    func sampleProductVariation(siteID: Int64,
                                productID: Int64,
                                id: Int64) -> ProductVariation {
        let imageSource = "https://i0.wp.com/funtestingusa.wpcomstaging.com/wp-content/uploads/2019/11/img_0002-1.jpeg?fit=4288%2C2848&ssl=1"
        return ProductVariation(siteID: siteID,
                                productID: productID,
                                productVariationID: id,
                                attributes: sampleProductVariationAttributes(),
                                image: ProductImage(imageID: 2432,
                                                    dateCreated: dateFromGMT("2020-03-13T03:13:57"),
                                                    dateModified: dateFromGMT("2020-07-21T08:29:16"),
                                                    src: imageSource,
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
                                manageStock: false,
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

    func sampleProductVariationAttributes() -> [ProductVariationAttribute] {
        return [
            ProductVariationAttribute(id: 0, name: "Darkness", option: "87%"),
            ProductVariationAttribute(id: 0, name: "Flavor", option: "strawberry"),
            ProductVariationAttribute(id: 0, name: "Shape", option: "marble")
        ]
    }

    func dateFromGMT(_ dateStringInGMT: String) -> Date {
        let dateFormatter = DateFormatter.Defaults.dateTimeFormatter
        return dateFormatter.date(from: dateStringInGMT)!
    }
}
