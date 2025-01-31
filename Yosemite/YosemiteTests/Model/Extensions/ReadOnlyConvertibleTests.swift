import XCTest
import CoreData
@testable import Yosemite
@testable import Storage

final class ReadOnlyConvertibleTests: XCTestCase {

    private let defaultDate = Date(timeIntervalSince1970: 0)

    func test_app_does_not_crash_when_converting_deleted_product() throws {
        // Given
        let storageManager = MockStorageManager()
        let createdDate = Date(timeIntervalSinceNow: -86_400) // 24h before
        let remoteItem = Product.fake().copy(siteID: 13, productID: 3, date: createdDate, dateCreated: createdDate)

        let fetchedItem = waitFor { promise in
            storageManager.performAndSave({ storage in
                let storedItem = storage.insertNewObject(ofType: Product.self)
                storedItem.update(with: remoteItem)
            }, completion: {
                // fetch the saved item from the view context
                let fetchedItem = storageManager.viewStorage.firstObject(ofType: Product.self)
                promise(fetchedItem)
            }, on: .main)
        }

        // confidence check
        XCTAssertNotNil(fetchedItem)

        // When: delete all stored objects
        waitForExpectation { expectation in
            storageManager.performAndSave({ storage in
                storage.deleteAllObjects(ofType: Product.self)
            }, completion: {
                XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: Product.self), 0)
                expectation.fulfill()
            }, on: .main)
        }

        // Then this should not crash
        let readOnlyItem = try XCTUnwrap(fetchedItem?.toReadOnly())
        // All properties are substituted to default values
        XCTAssertEqual(readOnlyItem.siteID, 0)
        XCTAssertEqual(readOnlyItem.productID, 0)
        XCTAssertEqual(readOnlyItem.date, defaultDate)
        XCTAssertEqual(readOnlyItem.dateCreated, defaultDate)
    }

    func test_app_does_not_crash_when_converting_deleted_product_image() throws {
        // Given
        let storageManager = MockStorageManager()
        let createdDate = Date(timeIntervalSinceNow: -86_400) // 24h before
        let remoteItem = ProductImage.fake().copy(imageID: 13, dateCreated: createdDate)

        let fetchedItem = waitFor { promise in
            storageManager.performAndSave({ storage in
                let storedItem = storage.insertNewObject(ofType: ProductImage.self)
                storedItem.update(with: remoteItem)
            }, completion: {
                // fetch the saved item from the view context
                let fetchedItem = storageManager.viewStorage.firstObject(ofType: ProductImage.self)
                promise(fetchedItem)
            }, on: .main)
        }

        // confidence check
        XCTAssertNotNil(fetchedItem)

        // When: delete all stored objects
        waitForExpectation { expectation in
            storageManager.performAndSave({ storage in
                storage.deleteAllObjects(ofType: ProductImage.self)
            }, completion: {
                XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: ProductImage.self), 0)
                expectation.fulfill()
            }, on: .main)
        }

        // Then this should not crash
        let readOnlyItem = try XCTUnwrap(fetchedItem?.toReadOnly())
        // All properties are substituted to default values
        XCTAssertEqual(readOnlyItem.imageID, 0)
        XCTAssertEqual(readOnlyItem.dateCreated, defaultDate)
    }

    func test_app_does_not_crash_when_converting_deleted_product_variation() throws {
        // Given
        let storageManager = MockStorageManager()
        let createdDate = Date(timeIntervalSinceNow: -86_400) // 24h before
        let remoteItem = ProductVariation.fake().copy(siteID: 13, productID: 3, productVariationID: 1, dateCreated: createdDate)

        let fetchedItem = waitFor { promise in
            storageManager.performAndSave({ storage in
                let storedItem = storage.insertNewObject(ofType: StorageProductVariation.self)
                storedItem.update(with: remoteItem)
            }, completion: {
                // fetch the saved item from the view context
                let fetchedItem = storageManager.viewStorage.firstObject(ofType: StorageProductVariation.self)
                promise(fetchedItem)
            }, on: .main)
        }

        // confidence check
        XCTAssertNotNil(fetchedItem)

        // When: delete all stored objects
        waitForExpectation { expectation in
            storageManager.performAndSave({ storage in
                storage.deleteAllObjects(ofType: StorageProductVariation.self)
            }, completion: {
                XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: StorageProductVariation.self), 0)
                expectation.fulfill()
            }, on: .main)
        }

        // Then this should not crash
        let readOnlyItem = try XCTUnwrap(fetchedItem?.toReadOnly())
        // All properties are substituted to default values
        XCTAssertEqual(readOnlyItem.siteID, 0)
        XCTAssertEqual(readOnlyItem.productID, 0)
        XCTAssertEqual(readOnlyItem.productVariationID, 0)
        XCTAssertEqual(readOnlyItem.dateCreated, defaultDate)
    }

    func test_app_does_not_crash_when_converting_deleted_shipping_label() throws {
        // Given
        let storageManager = MockStorageManager()
        let createdDate = Date(timeIntervalSinceNow: -86_400) // 24h before
        let remoteItem = ShippingLabel.fake().copy(siteID: 123, orderID: 44, shippingLabelID: 23, dateCreated: createdDate, status: .purchaseInProgress)

        let fetchedItem = waitFor { promise in
            storageManager.performAndSave({ storage in
                let storedItem = storage.insertNewObject(ofType: ShippingLabel.self)
                storedItem.update(with: remoteItem)
            }, completion: {
                // fetch the saved item from the view context
                let fetchedItem = storageManager.viewStorage.firstObject(ofType: ShippingLabel.self)
                promise(fetchedItem)
            }, on: .main)
        }

        // confidence check
        XCTAssertNotNil(fetchedItem)

        // When: delete all stored objects
        waitForExpectation { expectation in
            storageManager.performAndSave({ storage in
                storage.deleteAllObjects(ofType: ShippingLabel.self)
            }, completion: {
                XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: ShippingLabel.self), 0)
                expectation.fulfill()
            }, on: .main)
        }

        // Then this should not crash
        let readOnlyItem = try XCTUnwrap(fetchedItem?.toReadOnly())
        // All properties are substituted to default values
        XCTAssertEqual(readOnlyItem.siteID, 0)
        XCTAssertEqual(readOnlyItem.orderID, 0)
        XCTAssertEqual(readOnlyItem.shippingLabelID, 0)
        XCTAssertEqual(readOnlyItem.dateCreated, defaultDate)
        XCTAssertEqual(readOnlyItem.status, .unknown)
    }

    func test_app_does_not_crash_when_converting_deleted_shipping_label_refund() throws {
        // Given
        let storageManager = MockStorageManager()
        let dateRequested = Date(timeIntervalSinceNow: -86_400) // 24h before
        let remoteItem = ShippingLabelRefund(dateRequested: dateRequested, status: .pending)

        let fetchedItem = waitFor { promise in
            storageManager.performAndSave({ storage in
                let storedItem = storage.insertNewObject(ofType: ShippingLabelRefund.self)
                storedItem.update(with: remoteItem)
            }, completion: {
                // fetch the saved item from the view context
                let fetchedItem = storageManager.viewStorage.firstObject(ofType: ShippingLabelRefund.self)
                promise(fetchedItem)
            }, on: .main)
        }

        // confidence check
        XCTAssertNotNil(fetchedItem)

        // When: delete all stored objects
        waitForExpectation { expectation in
            storageManager.performAndSave({ storage in
                storage.deleteAllObjects(ofType: ShippingLabelRefund.self)
            }, completion: {
                XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: ShippingLabelRefund.self), 0)
                expectation.fulfill()
            }, on: .main)
        }

        // Then this should not crash
        let readOnlyItem = try XCTUnwrap(fetchedItem?.toReadOnly())
        // All properties are substituted to default values
        XCTAssertEqual(readOnlyItem.dateRequested, defaultDate)
        XCTAssertEqual(readOnlyItem.status, .unknown)
    }

    func test_app_does_not_crash_when_converting_deleted_wcpaycharge() throws {
        // Given
        let storageManager = MockStorageManager()
        let createdDate = Date(timeIntervalSinceNow: -86_400) // 24h before
        let remoteItem = WCPayCharge(siteID: 134,
                                     id: "21",
                                     amount: 23390,
                                     amountCaptured: 23390,
                                     amountRefunded: 0,
                                     authorizationCode: nil,
                                     captured: true,
                                     created: createdDate,
                                     currency: "USD",
                                     paid: true,
                                     paymentIntentID: nil,
                                     paymentMethodID: "test",
                                     paymentMethodDetails: .unknown,
                                     refunded: false,
                                     status: .succeeded)

        let fetchedItem = waitFor { promise in
            storageManager.performAndSave({ storage in
                let storedItem = storage.insertNewObject(ofType: WCPayCharge.self)
                storedItem.update(with: remoteItem)
            }, completion: {
                // fetch the saved item from the view context
                let fetchedItem = storageManager.viewStorage.firstObject(ofType: WCPayCharge.self)
                promise(fetchedItem)
            }, on: .main)
        }

        // confidence check
        XCTAssertNotNil(fetchedItem)

        // When: delete all stored objects
        waitForExpectation { expectation in
            storageManager.performAndSave({ storage in
                storage.deleteAllObjects(ofType: WCPayCharge.self)
            }, completion: {
                XCTAssertEqual(storageManager.viewStorage.countObjects(ofType: WCPayCharge.self), 0)
                expectation.fulfill()
            }, on: .main)
        }

        // Then this should not crash
        let readOnlyItem = try XCTUnwrap(fetchedItem?.toReadOnly())
        // All properties are substituted to default values
        XCTAssertEqual(readOnlyItem.siteID, 0)
        XCTAssertEqual(readOnlyItem.id, "")
        XCTAssertEqual(readOnlyItem.amount, 0)
        XCTAssertEqual(readOnlyItem.created, defaultDate)
    }
}
