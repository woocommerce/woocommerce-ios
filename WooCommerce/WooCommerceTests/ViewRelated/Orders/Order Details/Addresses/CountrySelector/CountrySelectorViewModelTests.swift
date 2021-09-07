import XCTest
import Yosemite
import TestKit
@testable import WooCommerce

final class CountrySelectorViewModelTests: XCTestCase {

    func test_filter_countries_return_expected_results() {
        // Given
        let viewModel = CountrySelectorViewModel()

        // When
        viewModel.searchTerm = "Co"
        let countries = viewModel.command.data.map { $0.name }
        // Then
        assertEqual(countries, [
            "Cocos (Keeling) Islands",
            "Congo - Kinshasa",
            "Congo - Brazzaville",
            "Cook Islands",
            "Colombia",
            "Costa Rica",
            "Comoros",
            "Morocco",
            "Monaco",
            "Mexico",
            "Puerto Rico",
            "Turks & Caicos Islands"
        ])
    }

    func test_filter_countries_with_uppercase_letters_return_expected_results() {
        // Given
        let viewModel = CountrySelectorViewModel()

        // When
        viewModel.searchTerm = "CO"
        let countries = viewModel.command.data.map { $0.name }
        // Then
        assertEqual(countries, [
            "Cocos (Keeling) Islands",
            "Congo - Kinshasa",
            "Congo - Brazzaville",
            "Cook Islands",
            "Colombia",
            "Costa Rica",
            "Comoros",
            "Morocco",
            "Monaco",
            "Mexico",
            "Puerto Rico",
            "Turks & Caicos Islands"
        ])
    }

    func test_cleaning_search_terms_return_all_countries() {
        // Given
        let viewModel = CountrySelectorViewModel()
        let totalNumberOfCountries = viewModel.command.data.count

        // When
        viewModel.searchTerm = "CO"
        XCTAssertNotEqual(viewModel.command.data.count, totalNumberOfCountries)
        viewModel.searchTerm = ""

        // Then
        XCTAssertEqual(viewModel.command.data.count, totalNumberOfCountries)
    }
}
