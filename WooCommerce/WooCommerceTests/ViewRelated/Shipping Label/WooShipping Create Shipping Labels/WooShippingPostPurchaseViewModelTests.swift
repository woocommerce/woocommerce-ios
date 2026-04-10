import XCTest
import YosemiteTestHelpers
@testable import WooCommerce
import Yosemite

final class WooShippingPostPurchaseViewModelTests: XCTestCase {

    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    func test_inits_with_provided_properties() {
        // Given
        let labelSizes: [ShippingLabelPaperSize] = [.label, .letter, .a4]
        let trackingURL = URL(string: "https://woocommerce.com")
        let pickupURL = WooShippingCarrier.usps.pickupURL
        let customsFormURL = URL(string: "https://example.com")

        // When
        let viewModel = WooShippingPostPurchaseViewModel(siteID: 123,
                                                         labelID: 1,
                                                         labelSizes: labelSizes,
                                                         isRefundable: true,
                                                         trackingURL: trackingURL,
                                                         pickupURL: pickupURL,
                                                         commercialInvoiceURL: customsFormURL)

        // Then
        XCTAssertEqual(viewModel.labelSizes, labelSizes)
        XCTAssertEqual(viewModel.trackingURL, trackingURL)
        XCTAssertEqual(viewModel.pickupURL, pickupURL)
        XCTAssertEqual(viewModel.commercialInvoiceURL, customsFormURL)
    }

    func test_labelSizes_excludes_a4_for_north_american_countries() {
        let northAmericanCountries = ["US", "CA", "MX", "DO"]

        for countryCode in northAmericanCountries {
            // Given
            let countrySetting = SiteSetting.fake().copy(settingID: "woocommerce_default_country",
                                                      value: countryCode)
            let siteAddress = SiteAddress(siteSettings: [countrySetting])

            // When
            let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: ShippingLabel.fake(),
                                                             siteAddress: siteAddress)

            // Then
            assertEqual([.label, .letter], viewModel.labelSizes)
        }
    }

    func test_labelSizes_includes_a4_for_non_north_american_countries() {
        let nonNorthAmericanCountries = ["GB", "FR", "DE", "IT", "ES", "NL", "AU", "JP"]

        for countryCode in nonNorthAmericanCountries {
            // Given
            let countrySetting = SiteSetting.fake().copy(settingID: "woocommerce_default_country",
                                                      value: countryCode)
            let siteAddress = SiteAddress(siteSettings: [countrySetting])

            // When
            let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: ShippingLabel.fake(),
                                                             siteAddress: siteAddress)

            // Then
            assertEqual([.label, .letter, .a4], viewModel.labelSizes)
        }
    }

    func test_trackingURL_parsed_from_shipping_label() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(carrierID: "usps", trackingNumber: "1234567890")

        // When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)

        // Then
        let expectedTrackingURL = ShippingLabelTrackingURLGenerator.url(for: shippingLabel)
        XCTAssertEqual(viewModel.trackingURL, expectedTrackingURL)
    }

    func test_pickupUP_parsed_from_shipping_label() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(carrierID: "usps")

        // When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)

        // Then
        XCTAssertEqual(viewModel.pickupURL, WooShippingCarrier.usps.pickupURL)
    }

    func test_commercialInvoiceURL_parsed_from_shipping_label() {
        // Given
        let customsFormURL = "https://example.com"
        let shippingLabel = ShippingLabel.fake().copy(commercialInvoiceURL: customsFormURL)

        // When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: shippingLabel)

        // Then
        XCTAssertEqual(viewModel.commercialInvoiceURL, URL(string: customsFormURL))
    }

    @MainActor
    func test_printLabel_fetches_label_data_from_remote() async throws {
        // Given
        var printData: ShippingLabelPrintData?
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .printLabel(_, _, _, completion):
                let data = ShippingLabelPrintData.fake()
                printData = data
                completion(.success(data))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: ShippingLabel.fake(), stores: stores)

        // When
        try await viewModel.printLabel()

        // Then
        XCTAssertNotNil(printData)
    }

    func test_selectedLabelSize_defaults_to_label() {
        // Given & When
        let viewModel = WooShippingPostPurchaseViewModel(shippingLabel: ShippingLabel.fake(), storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.selectedLabelSize, .label)
    }

    func test_selectedLabelSize_initialized_from_account_settings() {
        // Given
        let siteID: Int64 = 123

        // Insert account settings with A4 paper size
        let settings = ShippingLabelAccountSettings.fake().copy(siteID: siteID, paperSize: .a4)
        insertShippingLabelAccountSettings(readonlySettings: settings)

        // When
        let viewModel = WooShippingPostPurchaseViewModel(
            shippingLabel: ShippingLabel.fake().copy(siteID: siteID),
            storageManager: storageManager
        )

        // Then
        XCTAssertEqual(viewModel.selectedLabelSize, .a4)
    }
}

private extension WooShippingPostPurchaseViewModelTests {
    func insertShippingLabelAccountSettings(readonlySettings: ShippingLabelAccountSettings) {
        let storageSettings = storageManager.viewStorage.insertNewObject(ofType: StorageShippingLabelAccountSettings.self)
        storageSettings.update(with: readonlySettings)
    }
}
