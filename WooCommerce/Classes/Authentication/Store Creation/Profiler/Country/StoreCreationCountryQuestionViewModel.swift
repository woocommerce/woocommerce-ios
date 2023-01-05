import Combine
import Foundation

/// View model for `StoreCreationCountryQuestionView`, an optional profiler question about store country in the store creation flow.
@MainActor
final class StoreCreationCountryQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    typealias CountryCode = SiteAddress.CountryCode

    let topHeader: String

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

    init(storeName: String,
         currentLocale: Locale = .current,
         onContinue: @escaping (CountryCode) -> Void,
         onSupport: @escaping () -> Void) {
        self.topHeader = storeName
        self.onContinue = onContinue
        self.onSupport = onSupport

        currentCountryCode = currentLocale.regionCode.map { CountryCode(rawValue: $0) } ?? nil
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

    func continueButtonTapped() async {
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
        static let title = NSLocalizedString(
            "Confirm your location",
            comment: "Title of the store creation profiler question about the store country."
        )
        static let subtitle = NSLocalizedString(
            "We’ll use this information to get a head start on setting up payments, shipping, and taxes.",
            comment: "Subtitle of the store creation profiler question about the store country."
        )
    }
}
