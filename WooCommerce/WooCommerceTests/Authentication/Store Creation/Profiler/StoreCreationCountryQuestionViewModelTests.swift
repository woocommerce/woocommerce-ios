import Combine
import XCTest
@testable import WooCommerce

@MainActor
final class StoreCreationCountryQuestionViewModelTests: XCTestCase {
    private var subscriptions: Set<AnyCancellable> = []

    func test_topHeader_is_set_to_store_name() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store 🌟") { _ in } onSupport: {}

        // Then
        XCTAssertEqual(viewModel.topHeader, "store 🌟")
    }

    func test_currentCountryCode_and_initial_selectedCountryCode_are_set_by_locale() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store", currentLocale: .init(identifier: "fr_FR")) { _ in } onSupport: {}

        // Then
        XCTAssertEqual(viewModel.currentCountryCode, .FR)
        XCTAssertEqual(viewModel.selectedCountryCode, .FR)
    }

    func test_currentCountryCode_and_initial_selectedCountryCode_are_nil_with_an_invalid_locale() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store", currentLocale: .init(identifier: "zzzz")) { _ in } onSupport: {}

        // Then
        XCTAssertNil(viewModel.currentCountryCode)
        XCTAssertNil(viewModel.selectedCountryCode)
    }

    func test_countryCodes_include_all_countries_with_an_invalid_locale() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store", currentLocale: .init(identifier: "zzzz")) { _ in } onSupport: {}

        // Then
        XCTAssertEqual(viewModel.countryCodes, SiteAddress.CountryCode.allCases.sorted(by: { $0.readableCountry < $1.readableCountry }))
    }

    func test_countryCodes_do_not_include_currentCountryCode_from_locale() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store", currentLocale: .init(identifier: "fr_FR")) { _ in } onSupport: {}

        // Then
        XCTAssertFalse(viewModel.countryCodes.contains(.FR))
        XCTAssertEqual(viewModel.countryCodes.count, SiteAddress.CountryCode.allCases.count - 1)
    }

    func test_selecting_a_country_updates_selectedCountryCode() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store") { _ in } onSupport: {}

        // When
        viewModel.selectCountry(.FJ)

        // Then
        XCTAssertEqual(viewModel.selectedCountryCode, .FJ)
    }

    func test_selecting_a_country_sets_isContinueButtonEnabled_to_true_with_an_invalid_locale() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store", currentLocale: .init(identifier: "zzzz")) { _ in } onSupport: {}
        var isContinueButtonEnabledValues = [Bool]()
        viewModel.isContinueButtonEnabled.removeDuplicates().sink { isEnabled in
            isContinueButtonEnabledValues.append(isEnabled)
        }.store(in: &subscriptions)

        XCTAssertEqual(isContinueButtonEnabledValues, [false])

        // When
        viewModel.selectCountry(.FJ)

        // Then
        XCTAssertEqual(isContinueButtonEnabledValues, [false, true])
    }

    func test_isContinueButtonEnabled_stays_true_with_a_valid_locale() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store", currentLocale: .init(identifier: "fr_FR")) { _ in } onSupport: {}
        var isContinueButtonEnabledValues = [Bool]()
        viewModel.isContinueButtonEnabled.removeDuplicates().sink { isEnabled in
            isContinueButtonEnabledValues.append(isEnabled)
        }.store(in: &subscriptions)

        XCTAssertEqual(isContinueButtonEnabledValues, [true])

        // When
        viewModel.selectCountry(.FJ)

        // Then
        XCTAssertEqual(isContinueButtonEnabledValues, [true])
    }

    func test_continueButtonTapped_invokes_onContinue_after_selecting_a_country() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store",
                                                                  currentLocale: .init(identifier: "zzzz")) { countryCode in
                // Then
                XCTAssertEqual(countryCode, .JP)
                promise(())
            } onSupport: {}

            // When
            viewModel.selectCountry(.JP)
            Task { @MainActor in
                await viewModel.continueButtonTapped()
            }
        }
    }

    func test_continueButtonTapped_is_no_op_without_selecting_a_country() throws {
        // Given
        let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store",
                                                              currentLocale: .init(identifier: "zzzz")) { countryCode in
            // Then
            XCTFail("Should not be invoked without selecting a country.")
        } onSupport: {}
        // When
        Task { @MainActor in
            await viewModel.continueButtonTapped()
        }
    }

    func test_supportButtonTapped_invokes_onSupport() throws {
        waitFor { promise in
            // Given
            let viewModel = StoreCreationCountryQuestionViewModel(storeName: "store",
                                                                  currentLocale: .init(identifier: "")) { _ in } onSupport: {
                // Then
                promise(())
            }

            // When
            viewModel.supportButtonTapped()
        }
    }
}
