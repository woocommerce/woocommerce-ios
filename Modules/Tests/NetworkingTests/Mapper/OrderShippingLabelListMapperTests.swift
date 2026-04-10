import XCTest
@testable import Networking
@testable import NetworkingCore

/// OrderShippingLabelListMapper Unit Tests
///
final class OrderShippingLabelListMapperTests: XCTestCase {
    /// Site ID for testing.
    private let sampleSiteID: Int64 = 424242

    /// Order ID for testing.
    private let sampleOrderID: Int64 = 630

    func test_order_shipping_labels_and_settings_are_properly_parsed() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("order-shipping-labels"))

        // When
        let response = try OrderShippingLabelListMapper(siteID: sampleSiteID, orderID: sampleOrderID).map(response: jsonData)

        // Then
        XCTAssertEqual(response.settings, .init(siteID: sampleSiteID, orderID: sampleOrderID, paperSize: .label))

        let originAddress = ShippingLabelAddress(company: "fun testing",
                                                 name: "Woo seller",
                                                 phone: "6501234567",
                                                 country: "US",
                                                 state: "CA",
                                                 address1: "9999 19TH AVE",
                                                 address2: "",
                                                 city: "SAN FRANCISCO",
                                                 postcode: "94121-2303")
        let destinationAddress = ShippingLabelAddress(company: "",
                                                      name: "Woo buyer",
                                                      phone: "1650345689",
                                                      country: "TW",
                                                      state: "Taiwan",
                                                      address1: "No 70 RA St",
                                                      address2: "",
                                                      city: "Taipei",
                                                      postcode: "100")
        let shippingLabelWithoutRefund = ShippingLabel(siteID: sampleSiteID,
                                                       orderID: sampleOrderID,
                                                       shippingLabelID: 1149,
                                                       carrierID: "usps",
                                                       shipmentID: nil,
                                                       dateCreated: Date(timeIntervalSince1970: 1603716274.809),
                                                       packageName: "box",
                                                       rate: 58.81,
                                                       currency: "USD",
                                                       trackingNumber: "CM199912222US",
                                                       serviceName: "USPS - Priority Mail International",
                                                       refundableAmount: 58.81,
                                                       status: .purchased,
                                                       refund: nil,
                                                       originAddress: originAddress,
                                                       destinationAddress: destinationAddress,
                                                       productIDs: [3013],
                                                       productNames: ["Password protected!"],
                                                       commercialInvoiceURL: "https://woocommerce.com",
                                                       usedDate: nil,
                                                       expiryDate: Date(timeIntervalSince1970: 1619268278.000),
                                                       hazmatCategory: nil)
        let shippingLabelWithRefund = ShippingLabel(siteID: sampleSiteID,
                                                    orderID: sampleOrderID,
                                                    shippingLabelID: 2511668,
                                                    carrierID: "usps",
                                                    shipmentID: nil,
                                                    dateCreated: Date(timeIntervalSince1970: 1603715421.053),
                                                    packageName: "box",
                                                    rate: 74.44,
                                                    currency: "USD",
                                                    trackingNumber: "EQ12345678US",
                                                    serviceName: "USPS - Express Mail International",
                                                    refundableAmount: 74.44,
                                                    status: .purchased,
                                                    refund: .init(dateRequested: Date(timeIntervalSince1970: 1603715617.000), status: .pending),
                                                    originAddress: originAddress,
                                                    destinationAddress: destinationAddress,
                                                    productIDs: [3013],
                                                    productNames: ["Password protected!"],
                                                    commercialInvoiceURL: nil,
                                                    usedDate: nil,
                                                    expiryDate: Date(timeIntervalSince1970: 1619267426.000),
                                                    hazmatCategory: nil)
        XCTAssertEqual(response.shippingLabels, [shippingLabelWithoutRefund, shippingLabelWithRefund])
    }

    func test_order_shipping_labels_and_settings_are_properly_parsed_when_response_has_no_data_envelope() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("order-shipping-labels-without-data"))

        // When
        let response = try OrderShippingLabelListMapper(siteID: sampleSiteID, orderID: sampleOrderID).map(response: jsonData)

        // Then
        XCTAssertEqual(response.settings, .init(siteID: sampleSiteID, orderID: sampleOrderID, paperSize: .label))
        XCTAssertEqual(response.shippingLabels.count, 1)
    }

    func test_order_shipping_labels_mapper_filters_out_labels_with_error_in_labelsData() throws {
        // Given
        let jsonData = try XCTUnwrap(Loader.contentsOf("order-shipping-labels-with-error-in-labels-data"))

        // When
        let response = try OrderShippingLabelListMapper(siteID: sampleSiteID, orderID: sampleOrderID).map(response: jsonData)

        // Then
        XCTAssertEqual(response.settings, .init(siteID: sampleSiteID, orderID: sampleOrderID, paperSize: .label))
        XCTAssertEqual(response.shippingLabels.count, 3)
        XCTAssertFalse(response.shippingLabels.contains { $0.shippingLabelID == 4697 }, "Labels with error should be filtered out")
    }
}
