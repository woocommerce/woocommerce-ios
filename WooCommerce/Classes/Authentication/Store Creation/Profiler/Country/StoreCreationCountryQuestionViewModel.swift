import Combine
import Foundation
import WooFoundation

/// View model for `StoreCreationCountryQuestionView`, an optional profiler question about store country in the store creation flow.
final class StoreCreationCountryQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    let topHeader: String = Localization.header

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    /// TODO: 8378 - update values when API is ready.
    let countryCodes: [CountryCode]

    /// The estimated country code given the current device locale.
    let currentCountryCode: CountryCode?

    /// The currently selected country code.
    @Published private(set) var selectedCountryCode: CountryCode?

    /// Whether the continue button is enabled.
    @Published private var isContinueButtonEnabledValue: Bool = false

    private let onContinue: (CountryCode) -> Void
    private let onSupport: () -> Void

    init(currentLocale: Locale = .current,
         onContinue: @escaping (CountryCode) -> Void,
         onSupport: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onSupport = onSupport

        if let regionIdentifier = currentLocale.region?.identifier {
            currentCountryCode = CountryCode(rawValue: regionIdentifier)
        } else {
            currentCountryCode = nil
        }
        selectedCountryCode = currentCountryCode

        let allCountryCodes = CountryCode.allCases
            .sorted(by: { $0.readableCountry < $1.readableCountry })
        if let currentCountryCode {
            countryCodes = {
                var countryCodes = allCountryCodes
                countryCodes.removeAll(where: { $0 == currentCountryCode })
                return countryCodes
            }()
        } else {
            countryCodes = allCountryCodes
        }

        $selectedCountryCode
            .map { $0 != nil }
            .assign(to: &$isContinueButtonEnabledValue)
    }
}

extension StoreCreationCountryQuestionViewModel: RequiredStoreCreationProfilerQuestionViewModel {
    var isContinueButtonEnabled: AnyPublisher<Bool, Never> {
        $isContinueButtonEnabledValue.eraseToAnyPublisher()
    }

    func continueButtonTapped() {
        guard let selectedCountryCode else {
            return
        }
        onContinue(selectedCountryCode)
    }

    func supportButtonTapped() {
        onSupport()
    }
}

extension StoreCreationCountryQuestionViewModel {
    func selectCountry(_ countryCode: CountryCode) {
        selectedCountryCode = countryCode
    }
}

private extension StoreCreationCountryQuestionViewModel {
    enum Localization {
        static let header = NSLocalizedString(
            "About your store",
            comment: "Header of the store creation profiler question about the store country."
        )
        static let title = NSLocalizedString(
            "Where is your business located?",
            comment: "Title of the store creation profiler question about the store country."
        )
        static let subtitle = NSLocalizedString(
            "We will use this information to set up payments, shipping and taxes.",
            comment: "Subtitle of the store creation profiler question about the store country."
        )
    }
}
