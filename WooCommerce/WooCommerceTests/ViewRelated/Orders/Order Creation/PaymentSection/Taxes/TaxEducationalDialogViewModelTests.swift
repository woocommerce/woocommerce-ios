import XCTest
@testable import WooCommerce
import Yosemite
import WooFoundation

final class TaxEducationalDialogViewModelTests: XCTestCase {
    var viewModel: TaxEducationalDialogViewModel!
    var stores: MockStoresManager!

    func test_TaxEducationalDialogViewModelTests_when_we_pass_tax_lines_then_they_are_parsed() {
        // Given
        let taxLineOne = OrderTaxLine.fake().copy(label: "tax line 1", ratePercent: 10)
        let taxLineTwo = OrderTaxLine.fake().copy(label: "tax line 2", ratePercent: 50)

        let passingTaxLines = [taxLineOne, taxLineTwo]

        // When
        viewModel = TaxEducationalDialogViewModel(orderTaxLines: passingTaxLines, taxBasedOnSetting: nil)

        // Then
        XCTAssertEqual(viewModel.taxLines.count, passingTaxLines.count)
        XCTAssertEqual(viewModel.taxLines.first?.title, taxLineOne.label)
        XCTAssertEqual(viewModel.taxLines.first?.value, taxLineOne.ratePercent.percentFormatted())

        XCTAssertEqual(viewModel.taxLines.last?.title, taxLineTwo.label)
        XCTAssertEqual(viewModel.taxLines.last?.value, taxLineTwo.ratePercent.percentFormatted())
    }

    func test_TaxEducationalDialogViewModelTests_when_we_pass_billing_address_as_taxBasedOnSetting_then_property_is_updated() {
        // When
        viewModel = TaxEducationalDialogViewModel(orderTaxLines: [], taxBasedOnSetting: .customerBillingAddress)

        // Then
        XCTAssertEqual(viewModel.taxBasedOnSettingExplanatoryText,
                       NSLocalizedString("Your tax rate is currently calculated based on the customer billing address:", comment: ""))
    }

    func test_TaxEducationalDialogViewModelTests_when_we_pass_shipping_address_as_taxBasedOnSetting_then_property_is_updated() {
        // When
        viewModel = TaxEducationalDialogViewModel(orderTaxLines: [], taxBasedOnSetting: .customerShippingAddress)

        // Then
        XCTAssertEqual(viewModel.taxBasedOnSettingExplanatoryText,
                       NSLocalizedString("Your tax rate is currently calculated based on the customer shipping address:", comment: ""))
    }

    func test_TaxEducationalDialogViewModelTests_when_we_pass_shop_base_address_as_taxBasedOnSetting_then_property_is_updated() {
        // When
        viewModel = TaxEducationalDialogViewModel(orderTaxLines: [], taxBasedOnSetting: .shopBaseAddress)

        // Then
        XCTAssertEqual(viewModel.taxBasedOnSettingExplanatoryText,
                       NSLocalizedString("Your tax rate is currently calculated based on your shop address:", comment: ""))
    }

    func test_wpAdminTaxSettingsURL_passes_right_url() {
        // Given
        let sampleAdminURL = "https://testshop.com/wp-admin/"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        viewModel = TaxEducationalDialogViewModel(orderTaxLines: [], taxBasedOnSetting: .customerShippingAddress, stores: stores)

        let expectedURLString = sampleAdminURL + "admin.php?page=wc-settings&tab=tax"
        XCTAssertEqual(viewModel.wpAdminTaxSettingsURL?.absoluteString, expectedURLString)
    }

    func test_onGoToWpAdminButtonTapped_tracks_right_event() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        viewModel = TaxEducationalDialogViewModel(orderTaxLines: [], taxBasedOnSetting: nil, analytics: analytics)

        // When
        viewModel.onGoToWpAdminButtonTapped()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.taxEducationalDialogEditInAdminButtonTapped.rawValue)
    }
}
