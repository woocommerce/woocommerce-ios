import Testing
@testable import Hardware

/// Ensures that metadata is populated correctly
struct `Payment Intent Metadata Tests` {

    @Test func `no meta data`() {
        let metadata = PaymentIntent.initMetadata()
        #expect(metadata.count == 0)
    }

    @Test func `nil store`() {
        let metadata = PaymentIntent.initMetadata(store: nil)
        #expect(metadata.count == 0)
    }

    @Test func `non nil store`() throws {
        let metadata = PaymentIntent.initMetadata(store: "foo")
        let store = try #require(metadata["paymentintent.storename"])
        #expect(store == "foo")
        #expect(metadata.count == 1)
    }

    @Test func `nil customer name`() {
        let metadata = PaymentIntent.initMetadata(customerName: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func `non nil customer name`() throws {
        let metadata = PaymentIntent.initMetadata(customerName: "foo")
        let customerName = try #require(metadata["customer_name"])
        #expect(customerName == "foo")
        #expect(metadata.count == 1)
    }

    @Test func `nil customer email`() {
        let metadata = PaymentIntent.initMetadata(customerEmail: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func `non nil customer email`() throws {
        let metadata = PaymentIntent.initMetadata(customerEmail: "foo")
        let customerEmail = try #require(metadata["customer_email"])
        #expect(customerEmail == "foo")
        #expect(metadata.count == 1)
    }

    @Test func `nil site url`() {
        let metadata = PaymentIntent.initMetadata(siteURL: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func `non nil site url`() throws {
        let metadata = PaymentIntent.initMetadata(siteURL: "foo")
        let siteURL = try #require(metadata["site_url"])
        #expect(siteURL == "foo")
        #expect(metadata.count == 1)
    }

    @Test func `nil order id`() {
        let metadata = PaymentIntent.initMetadata(orderID: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func `non nil orderID`() throws {
        let metadata = PaymentIntent.initMetadata(orderID: 1234)
        let orderID = try #require(metadata["order_id"])
        #expect(orderID == "1234")
        #expect(metadata.count == 1)
    }

    @Test func `nil order key`() {
        let metadata = PaymentIntent.initMetadata(orderKey: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key is NOT changed unexpectedly
    /// since it is used by the backend as well.
    @Test func `non nil order key`() throws {
        let metadata = PaymentIntent.initMetadata(orderKey: "wc_order_0000000000000")
        let orderKey = try #require(metadata["order_key"])
        #expect(orderKey == "wc_order_0000000000000")
        #expect(metadata.count == 1)
    }

    @Test func `nil payment type`() {
        let metadata = PaymentIntent.initMetadata(paymentType: nil)
        #expect(metadata.count == 0)
    }

    /// Note: This test also ensures that encoding key and value are NOT changed unexpectedly
    /// since both are used by the backend as well.
    @Test func `single payment type`() throws {
        let metadata = PaymentIntent.initMetadata(paymentType: PaymentIntent.PaymentTypes.single)
        let paymentType = try #require(metadata["payment_type"])
        #expect(paymentType == "single")
        #expect(metadata.count == 1)
    }

    /// Note: This test also ensures that encoding key and value are NOT changed unexpectedly
    /// since both are used by the backend as well.
    @Test func `recurring payment type`() throws {
        let metadata = PaymentIntent.initMetadata(paymentType: PaymentIntent.PaymentTypes.recurring)
        let paymentType = try #require(metadata["payment_type"])
        #expect(paymentType == "recurring")
        #expect(metadata.count == 1)
    }

    @Test func `channel parameter sets ipp channel metadata`() throws {
        // Given
        let channelValues: [PaymentChannel] = [.storeManagement, .pos]
        let metadataValues = channelValues.map { PaymentIntent.initMetadata(channel: $0)["ipp_channel"] }

        // Then
        #expect(metadataValues == ["mobile_store_management", "mobile_pos"])
    }
}
