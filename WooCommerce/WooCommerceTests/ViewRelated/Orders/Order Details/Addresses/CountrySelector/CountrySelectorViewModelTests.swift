import XCTest
import Yosemite
import TestKit
@testable import WooCommerce

final class CountrySelectorViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123
    let testingStorage = MockStorageManager()

    override func setUp () {
        super.setUp()

        testingStorage.reset()
        testingStorage.insertSampleCountries(readOnlyCountries: Self.sampleCountries)
    }

    func test_filter_countries_return_expected_results() {
        // Given
        let viewModel = CountrySelectorViewModel(siteID: sampleSiteID, storageManager: testingStorage)

        // When
        viewModel.searchTerm = "Co"
        let countries = viewModel.command.data.map { $0.name }

        // Then
        assertEqual(countries, [
            "Cocos (Keeling) Islands",
            "Colombia",
            "Comoros",
            "Congo - Brazzaville",
            "Congo - Kinshasa",
            "Cook Islands",
            "Costa Rica",
            "Mexico",
            "Monaco",
            "Morocco",
            "Puerto Rico",
            "Turks & Caicos Islands"
        ])
    }

    func test_filter_countries_with_uppercase_letters_return_expected_results() {
        // Given
        let viewModel = CountrySelectorViewModel(siteID: sampleSiteID, storageManager: testingStorage)

        // When
        viewModel.searchTerm = "CO"
        let countries = viewModel.command.data.map { $0.name }

        // Then
        assertEqual(countries, [
            "Cocos (Keeling) Islands",
            "Colombia",
            "Comoros",
            "Congo - Brazzaville",
            "Congo - Kinshasa",
            "Cook Islands",
            "Costa Rica",
            "Mexico",
            "Monaco",
            "Morocco",
            "Puerto Rico",
            "Turks & Caicos Islands"
        ])
    }

    func test_cleaning_search_terms_return_all_countries() {
        // Given
        let viewModel = CountrySelectorViewModel(siteID: sampleSiteID, storageManager: testingStorage)
        let totalNumberOfCountries = viewModel.command.data.count

        // When
        viewModel.searchTerm = "CO"
        XCTAssertNotEqual(viewModel.command.data.count, totalNumberOfCountries)
        viewModel.searchTerm = ""

        // Then
        XCTAssertEqual(viewModel.command.data.count, totalNumberOfCountries)
    }

    func test_starting_view_model_without_stored_countries_fetches_them_remotely() {
        // Given
        testingStorage.reset()
        let testingStores = MockStoresManager(sessionManager: .testingInstance)


        // When
        let countriesFetched: Bool = waitFor { promise in
            testingStores.whenReceivingAction(ofType: DataAction.self) { action in
                switch action {
                case .synchronizeCountries:
                    promise(true)
                }
            }

            _ = CountrySelectorViewModel(siteID: self.sampleSiteID, storageManager: self.testingStorage, stores: testingStores)
        }

        // Then
        XCTAssertTrue(countriesFetched)
    }
}

// MARK: Helpers
private extension CountrySelectorViewModelTests {
    static let sampleCountries: [Country] = {
        return Locale.isoRegionCodes.map { regionCode in
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
            return Country(code: regionCode, name: name, states: [])
        }
    }()
}
