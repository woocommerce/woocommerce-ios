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
    @State private var isShowingCountryList = false
    @State private var searchText = ""

    init(viewModel: StoreCreationCountryQuestionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        RequiredStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    isShowingCountryList = true
                }, label: {
                    HStack(spacing: 16) {
                        if let flagEmoji = viewModel.currentCountryCode?.flagEmoji {
                            Text(flagEmoji)
                        }
                        Text(viewModel.currentCountryCode?.readableCountry ?? Localization.selectCountry)
                            .bodyStyle()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .secondaryBodyStyle()
                    }
                })
                .buttonStyle(SelectableSecondaryButtonStyle(isSelected: false))

                Text(Localization.preselected)
                    .footnoteStyle()
                    .renderedIf(viewModel.currentCountryCode != nil)
            }
        }
        .sheet(isPresented: $isShowingCountryList) {
            countryList
        }
    }

    @ViewBuilder
    var countryList: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    TextField(text: $searchText, prompt: Text(Localization.search)) {
                        Image(systemName: "magnifyingglass")
                    }
                    if searchText.isNotEmpty {
                        let results = viewModel.countryCodes.filter {
                            $0.readableCountry.contains(searchText)
                        }
                        if results.isNotEmpty {
                            StoreCreationCountrySectionView(header: Localization.searchResults.capitalized,
                                                            countryCodes: results,
                                                            viewModel: viewModel)
                        } else {
                            Text(Localization.noResults)
                        }
                    } else {
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
                .padding(16)
            }
            .navigationTitle(Localization.selectCountry)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancel) {
                        isShowingCountryList = false
                    }
                }
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
        static let searchResults = NSLocalizedString(
            "Search results",
            comment: "Header of the search results in the store creation country question."
        )
        static let selectCountry = NSLocalizedString(
            "Select country",
            comment: "Button to open the list of country to select for store creation profiler"
        )
        static let preselected = NSLocalizedString(
            "We’ve preselected your location. Please change it here if it's incorrect.",
            comment: "Label about preselected country in the store creation country question."
        )
        static let search = NSLocalizedString(
            "Search",
            comment: "Placeholder in the country search field in store creation profiler."
        )
        static let noResults = NSLocalizedString(
            "No Results",
            comment: "Text displayed when no countries are found upon filtering the country list in store creation profiler."
        )
        static let cancel = NSLocalizedString(
            "Cancel",
            comment: "Button to dismiss the country search view in the store creation profiler"
        )
    }
}

struct StoreCreationCountryQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreCreationCountryQuestionView(viewModel: .init(currentLocale: Locale.init(identifier: "en_US"),
                                                              onContinue: { _ in },
                                                              onSupport: {}))
        }
    }
}
