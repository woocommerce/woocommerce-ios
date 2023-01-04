import SwiftUI

/// Hosting controller that wraps the `StoreCreationCountryQuestionView`.
final class StoreCreationCountryQuestionHostingController: UIHostingController<StoreCreationCountryQuestionView> {
    init(viewModel: StoreCreationCountryQuestionViewModel) {
        super.init(rootView: StoreCreationCountryQuestionView(viewModel: viewModel))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Shows the store country question in the store creation flow.
struct StoreCreationCountryQuestionView: View {
    @StateObject private var viewModel: StoreCreationCountryQuestionViewModel

    init(viewModel: StoreCreationCountryQuestionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        RequiredStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(spacing: 32) {
                if let currentCountryCode = viewModel.currentCountryCode {
                    StoreCreationCountrySectionView(header: Localization.currentLocationHeader,
                                                    countryCodes: [currentCountryCode],
                                                    viewModel: viewModel)
                }
                StoreCreationCountrySectionView(header: Localization.otherCountriesHeader,
                                                countryCodes: viewModel.countryCodes,
                                                viewModel: viewModel)
            }
        }
    }
}

private extension StoreCreationCountryQuestionView {
    enum Localization {
        static let currentLocationHeader = NSLocalizedString(
            "CURRENT LOCATION",
            comment: "Header of the current country in the store creation country question.")
        static let otherCountriesHeader = NSLocalizedString(
            "COUNTRIES",
            comment: "Header of a list of other countries in the store creation country question.")
    }
}

struct StoreCreationCountryQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreCreationCountryQuestionView(viewModel: .init(storeName: "only in 2023",
                                                              currentLocale: Locale.init(identifier: "en_US"),
                                                              onContinue: { _ in },
                                                              onSupport: {}))
        }
    }
}
