import SwiftUI

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
            VStack(alignment: .leading, spacing: Layout.mainScreenSpacing) {
                Button(action: {
                    isShowingCountryList = true
                }, label: {
                    HStack(spacing: Layout.mainScreenFlagSpacing) {
                        viewModel.selectedCountryCode?.flagEmoji.map(Text.init)
                        Text(viewModel.selectedCountryCode?.readableCountry ?? Localization.selectCountry)
                            .bodyStyle()
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .secondaryBodyStyle()
                    }
                })
                .buttonStyle(SelectableSecondaryButtonStyle(isSelected: false))

                Text(Localization.preselected)
                    .footnoteStyle()
                    .renderedIf(viewModel.currentCountryCode == viewModel.selectedCountryCode)
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
                VStack(spacing: Layout.listScreenSpacing) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .secondaryBodyStyle()
                        TextField(Localization.search, text: $searchText)
                            .bodyStyle()
                    }
                    .padding(Layout.searchBarPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.searchBarCornerRadius)
                            .foregroundColor(.init(uiColor: .tertiarySystemFill))
                    )
                    if searchText.isNotEmpty {
                        // Search mode
                        let results = viewModel.countryCodes.filter {
                            $0.readableCountry.contains(searchText)
                        }
                        if results.isNotEmpty {
                            // Search results
                            StoreCreationCountrySectionView(header: Localization.searchResults.uppercased(),
                                                            countryCodes: results,
                                                            viewModel: viewModel)
                        } else {
                            // No results
                            Text(Localization.noResults)
                                .secondaryBodyStyle()
                        }
                    } else {
                        // Country list in normal mode
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
                .padding(Layout.listScreenPadding)
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
            .onChange(of: viewModel.selectedCountryCode) { newValue in
                if newValue != nil {
                    isShowingCountryList = false
                }
            }
            .onDisappear {
                searchText = ""
            }
        }
    }
}

private extension StoreCreationCountryQuestionView {
    enum Layout {
        static let mainScreenSpacing: CGFloat = 12
        static let mainScreenFlagSpacing: CGFloat = 16
        static let listScreenSpacing: CGFloat = 32
        static let listScreenPadding: CGFloat = 16
        static let searchBarPadding: CGFloat = 8
        static let searchBarCornerRadius: CGFloat = 8
    }
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
