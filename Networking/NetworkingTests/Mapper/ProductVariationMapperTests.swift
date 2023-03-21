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
    func test_ProductVariation_fields_are_properly_parsed() throws {
        let productVariation = try XCTUnwrap(mapLoadProductVariationResponse())

        XCTAssertEqual(productVariation, sampleProductVariation(siteID: dummySiteID, productID: dummyProductID, id: 2783))
    }

    /// Verifies that all of the ProductVariation Fields are parsed correctly when response has no data envelope.
    ///
    func test_ProductVariation_fields_are_properly_parsed_when_response_has_no_data_envelope() throws {
        let productVariation = try XCTUnwrap(mapLoadProductVariationResponseWithoutDataEnvelope())

        XCTAssertEqual(productVariation, sampleProductVariation(siteID: dummySiteID, productID: dummyProductID, id: 2783))
    }

    /// Verifies that the fields of the Product Variations with alternative types are parsed correctly when they have different types than in the struct.
    /// Currently, `price`, `regularPrice`, `salePrice`, `manageStock`, `purchasable`, and `permalink`  allow alternative types.
    ///
    func test_that_product_variations_alternative_types_are_properly_parsed() throws {
        let productVariation = try XCTUnwrap(mapLoadProductVariationResponseWithAlternativeTypes())

        XCTAssertEqual(productVariation.price, "13.99")
        XCTAssertEqual(productVariation.regularPrice, "16")
        XCTAssertEqual(productVariation.salePrice, "9.99")
        XCTAssertFalse(productVariation.manageStock)
        XCTAssertTrue(productVariation.purchasable)
        XCTAssertEqual(productVariation.permalink, "")
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

    /// Returns the ProductVariationMapper output upon receiving `ProductVariation`
    ///
    func mapLoadProductVariationResponseWithoutDataEnvelope() -> ProductVariation? {
        return mapProductVariation(from: "product-variation-update-without-data")
    }

    /// Returns the ProductVariationMapper output upon receiving `ProductVariation`
    ///
    func mapLoadProductVariationResponseWithAlternativeTypes() -> ProductVariation? {
        return mapProductVariation(from: "product-variation-alternative-types")
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
                                                    dateCreated: DateFormatter.dateFromString(with: "2020-03-13T03:13:57"),
                                                    dateModified: DateFormatter.dateFromString(with: "2020-07-21T08:29:16"),
                                                    src: imageSource,
                                                    name: "DSC_0010",
                                                    alt: ""),
                                permalink: "https://chocolate.com/marble",
                                dateCreated: DateFormatter.dateFromString(with: "2020-06-12T14:36:02"),
                                dateModified: DateFormatter.dateFromString(with: "2020-07-21T08:35:47"),
                                dateOnSaleStart: nil,
                                dateOnSaleEnd: nil,
                                status: .published,
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
}
