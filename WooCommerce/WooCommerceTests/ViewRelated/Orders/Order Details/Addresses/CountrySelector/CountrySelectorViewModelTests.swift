import XCTest
import Yosemite
import TestKit
import Combine
@testable import WooCommerce

final class CountrySelectorViewModelTests: XCTestCase {

    let selectedSubject = CurrentValueSubject<Country?, Never>(nil)
    var subscriptions = Set<AnyCancellable>()

    override func setUp () {
        super.setUp()

        selectedSubject.value = nil
        subscriptions.removeAll()
    }

    func test_filter_countries_return_expected_results() {
        // Given
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: selectedSubject)

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
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: selectedSubject)

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
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: selectedSubject)
        let totalNumberOfCountries = viewModel.command.data.count

        // When
        viewModel.searchTerm = "CO"
        XCTAssertNotEqual(viewModel.command.data.count, totalNumberOfCountries)
        viewModel.searchTerm = ""

        // Then
        XCTAssertEqual(viewModel.command.data.count, totalNumberOfCountries)
    }

    func test_providing_a_selected_country_is_reflected_on_command() {
        // Given
        let country = Self.sampleCountries[0]
        selectedSubject.value = country

        // When
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: selectedSubject)

        // Then
        XCTAssertEqual(viewModel.command.selected, country)
    }

    func test_selecting_country_via_command_updates_subject() {
        // Given
        let country = Self.sampleCountries[0]
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: selectedSubject)

        // When
        let viewController = ListSelectorViewController(command: viewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        viewModel.command.handleSelectedChange(selected: country, viewController: viewController)

        // Then
        XCTAssertEqual(selectedSubject.value, country)
    }
}

// MARK: Helpers
private extension CountrySelectorViewModelTests {
    static let sampleCountries: [Country] = {
        return Locale.isoRegionCodes.map { regionCode in
            let name = Locale.current.localizedString(forRegionCode: regionCode) ?? ""
            return Country(code: regionCode, name: name, states: [])
        }.sorted { a, b in
            a.name <= b.name
        }
    }()
}
