import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

struct ListMapperTests {

    @Test func test_item_fields_are_properly_parsed_from_jetpack_tunnelled_response() throws {
        // Given a response from a tunnelled Jetpack connection
        let responseWithDataEnvelope = try #require(Loader.contentsOf("orders-load-all"))

        // When we map orders
        let orders = try ListMapper<Order>(siteID: 123).map(response: responseWithDataEnvelope)

        // Then they are correctly decoded
        #expect(orders.count == 4)

        let firstOrder = orders[0]

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:12")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")
        let datePaid = DateFormatter.Defaults.dateTimeFormatter.date(from: "2018-04-03T23:05:14")

        #expect(firstOrder.orderID == 963)
        #expect(firstOrder.parentID == 0)
        #expect(firstOrder.customerID == 11)
        #expect(firstOrder.number == "963")
        #expect(firstOrder.status == .processing)
        #expect(firstOrder.currency == "USD")
        #expect(firstOrder.customerNote.isEmpty)
        #expect(firstOrder.dateCreated == dateCreated)
        #expect(firstOrder.dateModified == dateModified)
        #expect(firstOrder.datePaid == datePaid)
        #expect(firstOrder.discountTotal == "30.00")
        #expect(firstOrder.discountTax == "1.20")
        #expect(firstOrder.shippingTotal == "0.00")
        #expect(firstOrder.shippingTax == "0.00")
        #expect(firstOrder.total == "31.20")
        #expect(firstOrder.totalTax == "1.20")
    }

    @Test func test_item_fields_are_properly_parsed_from_direct_site_API_response() async throws {
        // Given a response from a direct site connection
        let responseWithoutDataEnvelope = try #require(Loader.contentsOf("products-load-all-without-data"))

        // When we map products
        let products = try ListMapper<Product>(siteID: 123).map(response: responseWithoutDataEnvelope)

        // Then they are correctly decoded
        #expect(products.count == 10)

        let firstProduct = products[0]

        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:33:31")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:48:01")

        #expect(firstProduct.siteID == 123)
        #expect(firstProduct.productID == 282)
        #expect(firstProduct.name == "Book the Green Room")
        #expect(firstProduct.slug == "book-the-green-room")
        #expect(firstProduct.permalink == "https://example.com/product/book-the-green-room/")
        #expect(firstProduct.dateCreated == dateCreated)
        #expect(firstProduct.dateModified == dateModified)
        #expect(firstProduct.productTypeKey == "booking")
        #expect(firstProduct.statusKey == "publish")
        #expect(firstProduct.featured == false)
        #expect(firstProduct.catalogVisibilityKey == "visible")
        #expect(firstProduct.fullDescription == "<p>This is the party room!</p>\n")
        #expect(firstProduct.shortDescription == """
                [contact-form]\n<p>The green room&#8217;s max capacity is 30 people. Reserving the date / time of your event is free. \
                We can also accommodate large groups, with seating for 85 board game players at a time. If you have a large group, let \
                us know and we&#8217;ll send you our large group rate.</p>\n<p>GROUP RATES</p>\n<p>Reserve your event for up to 30 guests for $100.</p>\n
                """)
        #expect(firstProduct.sku.isEmpty)
        #expect(firstProduct.price == "0")
        #expect(firstProduct.regularPrice.isEmpty)
        #expect(firstProduct.salePrice.isEmpty)
        #expect(firstProduct.onSale == false)
        #expect(firstProduct.purchasable == true)
        #expect(firstProduct.totalSales == 0)
        #expect(firstProduct.virtual == true)
        #expect(firstProduct.downloadable == false)
        #expect(firstProduct.downloadLimit == -1)
        #expect(firstProduct.downloadExpiry == -1)
        #expect(firstProduct.externalURL == "http://somewhere.com")
        #expect(firstProduct.taxStatusKey == "taxable")
        #expect(firstProduct.taxClass.isEmpty)
        #expect(firstProduct.manageStock == false)
        #expect(firstProduct.stockQuantity == nil)
        #expect(firstProduct.stockStatusKey == "instock")
        #expect(firstProduct.backordersKey == "no")
        #expect(firstProduct.backordersAllowed == false)
        #expect(firstProduct.backordered == false)
        #expect(firstProduct.soldIndividually == true)
        #expect(firstProduct.weight == "213")
        #expect(firstProduct.shippingRequired == false)
        #expect(firstProduct.shippingTaxable == false)
        #expect(firstProduct.shippingClass.isEmpty)
        #expect(firstProduct.shippingClassID == 0)
        #expect(firstProduct.reviewsAllowed == true)
        #expect(firstProduct.averageRating == "4.30")
        #expect(firstProduct.ratingCount == 23)
        #expect(firstProduct.relatedIDs == [31, 22, 369, 414, 56])
        #expect(firstProduct.upsellIDs == [99, 1234566])
        #expect(firstProduct.crossSellIDs == [1234, 234234, 3])
        #expect(firstProduct.parentID == 0)
        #expect(firstProduct.purchaseNote == "Thank you!")
        #expect(firstProduct.variations == [192, 194, 193])
        #expect(firstProduct.groupedProducts == [])
        #expect(firstProduct.menuOrder == 0)
        #expect(firstProduct.productType == ProductType(rawValue: "booking"))
    }

    @Test func test_site_identifier_is_properly_injected_into_every_item() throws {
        // Given 3 shipping classes in JSON
        let dummySiteID: Int64 = 242424
        let response = try #require(Loader.contentsOf("product-shipping-classes-load-all"))

        // When we map them
        let productShippingClasses = try ListMapper<ProductShippingClass>(siteID: dummySiteID).map(response: response)

        #expect(productShippingClasses.count == 3)

        for productShippingClass in productShippingClasses {
            // Then siteID is injected to each mapped model
            #expect(productShippingClass.siteID == dummySiteID)
        }
    }

    @Test func test_emptyDataResponse_mapsToEmptyArray() throws {
        // Given an empty response
        let response =  try #require(Loader.contentsOf("empty-data-array"))

        // When we map POSProducts
        let posProducts = try ListMapper<POSProduct>(siteID: 123).map(response: response)

        // Then we map to an empty array
        #expect(posProducts == [])
    }
}
