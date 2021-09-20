import XCTest
import Yosemite
import TestKit
import Combine
@testable import WooCommerce

final class CountrySelectorViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    override func setUp () {
        super.setUp()

        subscriptions.removeAll()
    }

    func test_filter_countries_return_expected_results() {
        // Given
        let binding = Binding<Country?>(get: { nil }, set: { _ in })
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: binding)

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
        let binding = Binding<Country?>(get: { nil }, set: { _ in })
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: binding)

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
        let binding = Binding<Country?>(get: { nil }, set: { _ in })
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: binding)
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
        let binding = Binding<Country?>(get: { Self.sampleCountries[0] }, set: { _ in })

        // When
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: binding)

        // Then
        XCTAssertEqual(viewModel.command.selected, binding.wrappedValue)
    }

    func test_selecting_country_via_command_updates_binding() {
        // Given
        let expectedCountry = Self.sampleCountries[0]
        var selectedCountry: Country? = nil
        let binding = Binding<Country?>(get: { selectedCountry }, set: { selectedCountry = $0 })
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: binding)

        // When
        let viewController = ListSelectorViewController(command: viewModel.command, onDismiss: { _ in }) // Needed because of legacy UIKit ways
        viewModel.command.handleSelectedChange(selected: expectedCountry, viewController: viewController)

        // Then
        XCTAssertEqual(selectedCountry, expectedCountry)
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
