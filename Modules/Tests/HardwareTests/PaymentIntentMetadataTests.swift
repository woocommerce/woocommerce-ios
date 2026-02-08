import Testing
@testable import Hardware

/// Ensures that metadata is populated correctly
@Suite("Payment Intent Metadata Tests")
struct PaymentIntentMetadataTests {

    @Test func test_no_meta_data() {
        let metadata = PaymentIntent.initMetadata()
        #expect(metadata.count == 0)
    }

    @Test func test_nil_store() {
        let metadata = PaymentIntent.initMetadata(store: nil)
        #expect(metadata.count == 0)
    }

    @Test func test_non_nil_store() throws {
        let metadata = PaymentIntent.initMetadata(store: "foo")
        let store = try #require(metadata["paymentintent.storename"])
        #expect(store == "foo")
        #expect(metadata.count == 1)
    }

    @Test func test_nil_customer_name() {
        let metadata = PaymentIntent.initMetadata(customerName: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func test_non_nil_customer_name() throws {
        let metadata = PaymentIntent.initMetadata(customerName: "foo")
        let customerName = try #require(metadata["customer_name"])
        #expect(customerName == "foo")
        #expect(metadata.count == 1)
    }

    @Test func test_nil_customer_email() {
        let metadata = PaymentIntent.initMetadata(customerEmail: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func test_non_nil_customer_email() throws {
        let metadata = PaymentIntent.initMetadata(customerEmail: "foo")
        let customerEmail = try #require(metadata["customer_email"])
        #expect(customerEmail == "foo")
        #expect(metadata.count == 1)
    }

    @Test func test_nil_site_url() {
        let metadata = PaymentIntent.initMetadata(siteURL: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func test_non_nil_site_url() throws {
        let metadata = PaymentIntent.initMetadata(siteURL: "foo")
        let siteURL = try #require(metadata["site_url"])
        #expect(siteURL == "foo")
        #expect(metadata.count == 1)
    }

    @Test func test_nil_order_id() {
        let metadata = PaymentIntent.initMetadata(orderID: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func test_non_nil_orderID() throws {
        let metadata = PaymentIntent.initMetadata(orderID: 1234)
        let orderID = try #require(metadata["order_id"])
        #expect(orderID == "1234")
        #expect(metadata.count == 1)
    }

    @Test func test_nil_order_key() {
        let metadata = PaymentIntent.initMetadata(orderKey: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func test_non_nil_order_key() throws {
        let metadata = PaymentIntent.initMetadata(orderKey: "wc_order_0000000000000")
        let orderKey = try #require(metadata["order_key"])
        #expect(orderKey == "wc_order_0000000000000")
        #expect(metadata.count == 1)
    }

    @Test func test_nil_payment_type() {
        let metadata = PaymentIntent.initMetadata(paymentType: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key and value are NOT changed unexpectedly
    /// since both are used by the backend as well.
    @Test func test_single_payment_type() throws {
        let metadata = PaymentIntent.initMetadata(paymentType: PaymentIntent.PaymentTypes.single)
        let paymentType = try #require(metadata["payment_type"])
        #expect(paymentType == "single")
        #expect(metadata.count == 1)
    }

    /// Note: This test also ensures that encoding key and value are NOT changed unexpectedly
    /// since both are used by the backend as well.
    @Test func test_recurring_payment_type() throws {
        let metadata = PaymentIntent.initMetadata(paymentType: PaymentIntent.PaymentTypes.recurring)
        let paymentType = try #require(metadata["payment_type"])
        #expect(paymentType == "recurring")
        #expect(metadata.count == 1)
    }

    @Test func test_channel_parameter_sets_ipp_channel_metadata() throws {
        // Given
        let channelValues: [PaymentChannel] = [.storeManagement, .pos]
        let metadataValues = channelValues.map { PaymentIntent.initMetadata(channel: $0)["ipp_channel"] }

        // Then
        #expect(metadataValues == ["mobile_store_management", "mobile_pos"])
    }
}
