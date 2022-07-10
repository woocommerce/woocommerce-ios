import XCTest
import Yosemite
@testable import WooCommerce

class CardReaderManualsViewModelTests: XCTestCase {

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageManager = MockStorageManager()
    }

    override func tearDownWithError() throws {
        storageManager = nil
        try super.tearDownWithError()
    }

    func test_viewModel_not_nil() {
        // Given
        let viewModel = CardReaderManualsViewModel()

        // When
        XCTAssertNotNil(viewModel)
    }

    func test_viewModel_when_init_then_has_default_manuals() {
         // Given
         let viewModel = CardReaderManualsViewModel()

         // When
         let expectedManuals = viewModel.manuals

         // Then
         XCTAssertEqual(viewModel.manuals, expectedManuals)
     }

    func test_viewModel_when_US_store_then_available_card_reader_manuals() {
        // Given
        let setting = SiteSetting.fake()
                    .copy(
                        siteID: sampleSiteID,
                        settingID: "woocommerce_default_country",
                        value: "US:CA"
                    )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        let viewModel = CardReaderManualsViewModel()

        // When
        let availableReaderTypes = [CardReaderType.chipper, CardReaderType.stripeM2]
        let expectedManuals = availableReaderTypes.map { $0.manual }

        // Then
        XCTAssertEqual(viewModel.manuals, expectedManuals)
    }

    func test_viewModel_when_CA_store_then_available_card_reader_manuals() {
        // Given
        let setting = SiteSetting.fake()
                    .copy(
                        siteID: sampleSiteID,
                        settingID: "woocommerce_default_country",
                        value: "CA:NS"
                    )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        let viewModel = CardReaderManualsViewModel()

        // When
        let availableReaderTypes = [CardReaderType.wisepad3]
        let expectedManuals = availableReaderTypes.map { $0.manual }

        // Then
        XCTAssertEqual(viewModel.manuals, expectedManuals)
    }

    func test_viewModel_when_IPP_not_available_country_then_available_card_reader_manuals_is_empty() {
        // Given
        let setting = SiteSetting.fake()
                    .copy(
                        siteID: sampleSiteID,
                        settingID: "woocommerce_default_country",
                        value: "ES"
                    )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        let viewModel = CardReaderManualsViewModel()

        // When
        let availableReaderTypes: [CardReaderType] = []
        let expectedManuals = availableReaderTypes.map { $0.manual }

        // Then
        XCTAssertEqual(viewModel.manuals, expectedManuals)
    }
}
