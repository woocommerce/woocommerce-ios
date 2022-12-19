import XCTest
import Yosemite
import TestKit
import Combine
@testable import WooCommerce

final class CountrySelectorViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()
    var binding: Binding<AreaSelectorCommandProtocol?>!
    var viewModel: CountrySelectorViewModel!

    override func setUp () {
        super.setUp()

        binding = Binding<AreaSelectorCommandProtocol?>(get: { nil }, set: { _ in })
        viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: binding)
    }

    override func tearDown() {
        subscriptions.removeAll()
        binding = nil
        viewModel = nil
        super.tearDown()
    }

    func test_filter_countries_return_expected_results() {
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

    func test_filter_term_with_last_character_whitespace_return_expected_result() {
        // When
        viewModel.searchTerm = "Indonesia "
        let countries = viewModel.command.data.map { $0.name }

        // Then
        assertEqual(countries, [
            "Indonesia"
        ])
    }

    func test_filter_term_with_last_character_newline_return_expected_result() {
        // When
        viewModel.searchTerm = "Indonesia\n"
        let countries = viewModel.command.data.map { $0.name }

        // Then
        assertEqual(countries, [
            "Indonesia"
        ])
    }

    func test_filter_countries_with_uppercase_letters_return_expected_results() {
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
        let binding = Binding<AreaSelectorCommandProtocol?>(get: { Self.sampleCountries[0]}, set: { _ in })

        // When
        let viewModel = CountrySelectorViewModel(countries: Self.sampleCountries, selected: binding)

        // Then
        XCTAssertEqual(viewModel.command.selected?.name, binding.wrappedValue?.name)
    }

    func test_selecting_country_via_command_updates_binding() {
        // Given
        let expectedCountry = Self.sampleCountries[0]
        var selectedCountry: Country? = nil
        let binding = Binding<AreaSelectorCommandProtocol?>(get: { selectedCountry }, set: { selectedCountry = $0 as? Country})
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
