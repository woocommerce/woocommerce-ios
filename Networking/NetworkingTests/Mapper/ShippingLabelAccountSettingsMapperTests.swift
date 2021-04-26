import Foundation
import XCTest
@testable import Networking

/// Unit Tests for `ShippingLabelAccountSettingsMapper`
///
class ShippingLabelAccountSettingsMapperTests: XCTestCase {

    /// Sample Site ID
    private let sampleSiteID: Int64 = 123456

    /// Verifies that the Shipping Label Account Settings are parsed correctly.
    ///
    func test_Account_Settings_are_properly_parsed() {
        guard let settings = mapLoadShippingLabelAccountSettings() else {
            XCTFail()
            return
        }

        XCTAssertEqual(settings.siteID, sampleSiteID)
        XCTAssertEqual(settings.canEditSettings, true)
        XCTAssertEqual(settings.canManagePayments, true)
        XCTAssertEqual(settings.isEmailReceiptsEnabled, true)
        XCTAssertEqual(settings.lastSelectedPackageID, "small_flat_box")
        XCTAssertEqual(settings.paperSize, .label)
        XCTAssertEqual(settings.paymentMethods, [sampleShippingLabelPaymentMethod()])
        XCTAssertEqual(settings.selectedPaymentMethodID, 11743265)
        XCTAssertEqual(settings.storeOwnerDisplayName, "Example User")
        XCTAssertEqual(settings.storeOwnerUsername, "admin")
        XCTAssertEqual(settings.storeOwnerWpcomEmail, "example@example.com")
        XCTAssertEqual(settings.storeOwnerWpcomUsername, "apiexamples")
    }

    /// Verifies that the Shipping Label Account Settings without any payment methods are parsed correctly.
    ///
    func test_Account_Settings_without_payment_methods_are_properly_parsed() {
        guard let settings = mapLoadIncompleteShippingLabelAccountSettings() else {
            XCTFail()
            return
        }

        XCTAssertEqual(settings.siteID, sampleSiteID)
        XCTAssertEqual(settings.canEditSettings, true)
        XCTAssertEqual(settings.canManagePayments, false)
        XCTAssertEqual(settings.isEmailReceiptsEnabled, true)
        XCTAssertEqual(settings.lastSelectedPackageID, "")
        XCTAssertEqual(settings.paperSize, .label)
        XCTAssertEqual(settings.paymentMethods, [])
        XCTAssertEqual(settings.selectedPaymentMethodID, 0)
        XCTAssertEqual(settings.storeOwnerDisplayName, "Example User")
        XCTAssertEqual(settings.storeOwnerUsername, "admin")
        XCTAssertEqual(settings.storeOwnerWpcomEmail, "example@example.com")
        XCTAssertEqual(settings.storeOwnerWpcomUsername, "apiexamples")
    }

}

/// Private Helpers
///
private extension ShippingLabelAccountSettingsMapperTests {

    /// Returns the ShippingLabelAccountSettingsMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapAccountSettings(from filename: String) -> ShippingLabelAccountSettings? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try! ShippingLabelAccountSettingsMapper(siteID: sampleSiteID).map(response: response)
    }

    /// Returns the ShippingLabelAccountSettingsMapper output upon receiving `shipping-label-account-settings`
    ///
    func mapLoadShippingLabelAccountSettings() -> ShippingLabelAccountSettings? {
        return mapAccountSettings(from: "shipping-label-account-settings")
    }

    /// Returns the ShippingLabelAccountSettingsMapper output upon receiving `shipping-label-account-settings-no-payment-methods`
    ///
    func mapLoadIncompleteShippingLabelAccountSettings() -> ShippingLabelAccountSettings? {
        return mapAccountSettings(from: "shipping-label-account-settings-no-payment-methods")
    }
}

private extension ShippingLabelAccountSettingsMapperTests {
    func sampleShippingLabelPaymentMethod() -> ShippingLabelPaymentMethod {
        return ShippingLabelPaymentMethod(paymentMethodID: 11743265,
                                          name: "Example User",
                                          cardType: .visa,
                                          cardDigits: "4242",
                                          expiry: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2030-12-31"))
    }
}
