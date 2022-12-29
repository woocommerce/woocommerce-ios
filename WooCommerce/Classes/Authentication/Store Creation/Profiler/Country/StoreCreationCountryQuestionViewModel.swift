import Combine
import Foundation

/// View model for `StoreCreationCountryQuestionView`, an optional profiler question about store country in the store creation flow.
final class StoreCreationCountryQuestionViewModel: StoreCreationProfilerQuestionViewModel, ObservableObject {
    /// Contains necessary information about a category.
    struct Category: Equatable {
        /// Display name for the category.
        let name: String
        /// Value that is sent to the API.
        let value: String
    }

    let topHeader: String

    let title: String = Localization.title

    let subtitle: String = Localization.subtitle

    /// Question content.
    /// TODO: 8378 - update values when API is ready.
    let countryCodes: [SiteAddress.CountryCode] = SiteAddress.CountryCode.allCases

    @Published private(set) var selectedCountryCode: SiteAddress.CountryCode?

    @Published private var isContinueButtonEnabledValue: Bool = false

    private let onContinue: (SiteAddress.CountryCode) -> Void
    private let onSkip: () -> Void

    init(storeName: String,
         onContinue: @escaping (SiteAddress.CountryCode) -> Void,
         onSkip: @escaping () -> Void) {
        self.topHeader = storeName
        self.onContinue = onContinue
        self.onSkip = onSkip

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
            return onSkip()
        }
        onContinue(selectedCountryCode)
    }
}

extension StoreCreationCountryQuestionViewModel {
    func selectCountry(_ countryCode: SiteAddress.CountryCode) {
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
