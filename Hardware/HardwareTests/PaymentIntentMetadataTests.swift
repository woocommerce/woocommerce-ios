import XCTest
@testable import Hardware

/// Ensures that metadata is populated correctly
///
final class PaymentIntentMetadataTests: XCTestCase {

    func test_no_meta_data() {
        let metadata = PaymentIntent.initMetadata()
        XCTAssertEqual(metadata.count, 0)
    }

    func test_nil_store() {
        let metadata = PaymentIntent.initMetadata(store: nil)
        XCTAssertEqual(metadata.count, 0)
    }

    func test_non_nil_store() throws {
        let metadata = PaymentIntent.initMetadata(store: "foo")
        let store = try XCTUnwrap(metadata["paymentintent.storename"])
        XCTAssertEqual(store, "foo")
        XCTAssertEqual(metadata.count, 1)
    }

    func test_nil_customer_name() {
        let metadata = PaymentIntent.initMetadata(customerName: nil)
        XCTAssertEqual(metadata.count, 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    ///
    func test_non_nil_customer_name() throws {
        let metadata = PaymentIntent.initMetadata(customerName: "foo")
        let customerName = try XCTUnwrap(metadata["customer_name"])
        XCTAssertEqual(customerName, "foo")
        XCTAssertEqual(metadata.count, 1)
    }

    func test_nil_customer_email() {
        let metadata = PaymentIntent.initMetadata(customerEmail: nil)
        XCTAssertEqual(metadata.count, 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    ///
    func test_non_nil_customer_email() throws {
        let metadata = PaymentIntent.initMetadata(customerEmail: "foo")
        let customerEmail = try XCTUnwrap(metadata["customer_email"])
        XCTAssertEqual(customerEmail, "foo")
        XCTAssertEqual(metadata.count, 1)
    }

    func test_nil_site_url() {
        let metadata = PaymentIntent.initMetadata(siteURL: nil)
        XCTAssertEqual(metadata.count, 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    ///
    func test_non_nil_site_url() throws {
        let metadata = PaymentIntent.initMetadata(siteURL: "foo")
        let siteURL = try XCTUnwrap(metadata["site_url"])
        XCTAssertEqual(siteURL, "foo")
        XCTAssertEqual(metadata.count, 1)
    }

    func test_nil_order_id() {
        let metadata = PaymentIntent.initMetadata(orderID: nil)
        XCTAssertEqual(metadata.count, 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    ///
    func test_non_nil_orderID() throws {
        let metadata = PaymentIntent.initMetadata(orderID: 1234)
        let orderID = try XCTUnwrap(metadata["order_id"])
        XCTAssertEqual(orderID, "1234")
        XCTAssertEqual(metadata.count, 1)
    }

    func test_nil_order_key() {
        let metadata = PaymentIntent.initMetadata(orderKey: nil)
        XCTAssertEqual(metadata.count, 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    ///
    func test_non_nil_order_key() throws {
        let metadata = PaymentIntent.initMetadata(orderKey: "wc_order_0000000000000")
        let orderKey = try XCTUnwrap(metadata["order_key"])
        XCTAssertEqual(orderKey, "wc_order_0000000000000")
        XCTAssertEqual(metadata.count, 1)
    }

    func test_nil_payment_type() {
        let metadata = PaymentIntent.initMetadata(paymentType: nil)
        XCTAssertEqual(metadata.count, 0)
    }

    /// Note: This test also ensures that encoding key and value are NOT changed unexpectedly
    /// since both are used by the backend as well.
    ///
    func test_single_payment_type() throws {
        let metadata = PaymentIntent.initMetadata(paymentType: PaymentIntent.PaymentTypes.single)
        let paymentType = try XCTUnwrap(metadata["payment_type"])
        XCTAssertEqual(paymentType, "single")
        XCTAssertEqual(metadata.count, 1)
    }

    /// Note: This test also ensures that encoding key and value are NOT changed unexpectedly
    /// since both are used by the backend as well.
    ///
    func test_recurring_payment_type() throws {
        let metadata = PaymentIntent.initMetadata(paymentType: PaymentIntent.PaymentTypes.recurring)
        let paymentType = try XCTUnwrap(metadata["payment_type"])
        XCTAssertEqual(paymentType, "recurring")
        XCTAssertEqual(metadata.count, 1)
    }
}
