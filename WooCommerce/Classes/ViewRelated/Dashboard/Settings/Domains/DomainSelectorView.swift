import SwiftUI

/// Hosting controller that wraps the `DomainSelectorView` view with free domains.
final class FreeDomainSelectorHostingController: UIHostingController<DomainSelectorView<FreeDomainSelectorDataProvider, FreeDomainSuggestionViewModel>> {
    /// - Parameters:
    ///   - viewModel: View model for the domain selector.
    ///   - onDomainSelection: Called when the user continues with a selected domain.
    ///   - onSupport: Called when the user taps to contact support.
    init(viewModel: DomainSelectorViewModel<FreeDomainSelectorDataProvider, FreeDomainSuggestionViewModel>,
         onDomainSelection: @escaping (FreeDomainSuggestionViewModel) async -> Void,
         onSupport: @escaping () -> Void) {
        super.init(rootView: DomainSelectorView<FreeDomainSelectorDataProvider, FreeDomainSuggestionViewModel>(viewModel: viewModel,
                                                                                                               onDomainSelection: onDomainSelection,
                                                                                                               onSupport: onSupport))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Hosting controller that wraps the `DomainSelectorView` view with paid domains.
final class PaidDomainSelectorHostingController: UIHostingController<DomainSelectorView<PaidDomainSelectorDataProvider, PaidDomainSuggestionViewModel>> {
    /// - Parameters:
    ///   - viewModel: View model for the domain selector.
    ///   - onDomainSelection: Called when the user continues with a selected domain.
    ///   - onSupport: Called when the user taps to contact support.
    init(viewModel: DomainSelectorViewModel<PaidDomainSelectorDataProvider, PaidDomainSuggestionViewModel>,
         onDomainSelection: @escaping (PaidDomainSuggestionViewModel) async -> Void,
         onSupport: @escaping () -> Void) {
        super.init(rootView: DomainSelectorView<PaidDomainSelectorDataProvider, PaidDomainSuggestionViewModel>(viewModel: viewModel,
                                                                                                      onDomainSelection: onDomainSelection,
                                                                                                      onSupport: onSupport))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTransparentNavigationBar()
    }
}

/// Allows the user to search for a domain and then select one to continue.
struct DomainSelectorView<DataProvider: DomainSelectorDataProvider,
                          DomainSuggestion: Equatable & DomainSuggestionViewProperties>: View
where DataProvider.DomainSuggestion == DomainSuggestion {
    private let onDomainSelection: (DomainSuggestion) async -> Void
    private let onSupport: () -> Void

    /// View model to drive the view.
    @ObservedObject private var viewModel: DomainSelectorViewModel<DataProvider, DomainSuggestion>

    /// Currently selected domain.
    /// If this property is kept in the view model, a SwiftUI error appears `Publishing changes from within view updates`
    /// when a domain row is selected.
    @State private var selectedDomain: DomainSuggestion?

    @State private var isWaitingForDomainSelectionCompletion: Bool = false

    @FocusState private var textFieldIsFocused: Bool

    init(viewModel: DomainSelectorViewModel<DataProvider, DomainSuggestion>,
         onDomainSelection: @escaping (DomainSuggestion) async -> Void,
         onSupport: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDomainSelection = onDomainSelection
        self.onSupport = onSupport
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header label.
                Text(Localization.subtitle)
                    .foregroundColor(Color(.secondaryLabel))
                    .bodyStyle()
                    .padding(.horizontal, Layout.defaultHorizontalPadding)
                    .padding(.top, 16)

                Spacer()
                    .frame(height: 30)

                // Search text field.
                SearchHeader(text: $viewModel.searchTerm,
                             placeholder: Localization.searchPlaceholder,
                             customizations: .init(backgroundColor: .clear,
                                                   borderColor: .separator,
                                                   internalHorizontalPadding: 21,
                                                   internalVerticalPadding: 12,
                                                   iconSize: .init(width: 14, height: 14)))
                .focused($textFieldIsFocused)

                switch viewModel.state {
                case .placeholder:
                    // Placeholder image when search query is empty.
                    Spacer()
                        .frame(height: 30)

                    HStack {
                        Spacer()
                        Image(uiImage: .domainSearchPlaceholderImage)
                        Spacer()
                    }
                case .loading:
                    // Progress indicator when loading domain suggestions.
                    Spacer()
                        .frame(height: 23)

                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case .error(let errorMessage):
                    // Error message when there is an error loading domain suggestions.
                    Spacer()
                        .frame(height: 23)

                    Text(errorMessage)
                        .foregroundColor(Color(.secondaryLabel))
                        .bodyStyle()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(Layout.defaultPadding)
                case .results(let domains):
                    // Domain suggestions.
                    Text(Localization.suggestionsHeader)
                        .foregroundColor(Color(.secondaryLabel))
                        .footnoteStyle()
                        .padding(.horizontal, Layout.defaultHorizontalPadding)
                        .padding(.vertical, insets: .init(top: 14, leading: 0, bottom: 8, trailing: 0))

                    LazyVStack {
                        ForEach(domains, id: \.name) { domain in
                            Button {
                                textFieldIsFocused = false
                                selectedDomain = domain
                            } label: {
                                VStack(alignment: .leading) {
                                    DomainRowView(viewModel:
                                            .init(domainName: domain.name,
                                                  attributedDetail: domain.attributedDetail,
                                                  searchQuery: viewModel.searchTerm,
                                                  isSelected: domain == selectedDomain))
                                    Divider()
                                        .dividerStyle()
                                        .padding(.leading, Layout.defaultHorizontalPadding)
                                }
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Continue button when a domain is selected.
            if let selectedDomain {
                VStack {
                    Divider()
                        .dividerStyle()
                    Button(Localization.continueButtonTitle) {
                        Task { @MainActor in
                            isWaitingForDomainSelectionCompletion = true
                            await onDomainSelection(selectedDomain)
                            isWaitingForDomainSelectionCompletion = false
                        }
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isWaitingForDomainSelectionCompletion))
                    .padding(Layout.defaultPadding)
                }
                .background(Color(.systemBackground))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SupportButton {
                    onSupport()
                }
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: viewModel.isLoadingDomainSuggestions) { isLoadingDomainSuggestions in
            // Resets selected domain when loading domain suggestions.
            if isLoadingDomainSuggestions {
                selectedDomain = nil
            }
        }
    }
}

/// Constants are computed static properties since stored properties are not supported in generic types.
private extension DomainSelectorView {
    enum Layout {
        static var defaultHorizontalPadding: CGFloat { 16 }
        static var defaultPadding: EdgeInsets { .init(top: 10, leading: 16, bottom: 10, trailing: 16) }
    }

    enum Localization {
        static var title: String {
            NSLocalizedString("Choose a domain", comment: "Title of the domain selector.")
        }
        static var subtitle: String {
            NSLocalizedString(
                "This is where people will find you on the Internet. You can add another domain later.",
                comment: "Subtitle of the domain selector.")
        }
        static var searchPlaceholder: String {
            NSLocalizedString("Type a name for your store", comment: "Placeholder of the search text field on the domain selector.")
        }
        static var suggestionsHeader: String {
            NSLocalizedString("SUGGESTIONS", comment: "Header label of the domain suggestions on the domain selector.")
        }
        static var continueButtonTitle: String {
            NSLocalizedString("Continue", comment: "Title of the button to continue with a selected domain.")
        }
    }
}

#if DEBUG

import Yosemite
import enum Networking.DotcomError

/// StoresManager that specifically handles `DomainAction` for `DomainSelectorView` previews.
final class DomainSelectorViewStores: DefaultStoresManager {
    private let freeDomainsResult: Result<[FreeDomainSuggestion], Error>?
    private let paidDomainsResult: Result<[PaidDomainSuggestion], Error>?

    init(freeDomainsResult: Result<[FreeDomainSuggestion], Error>? = nil,
         paidDomainsResult: Result<[PaidDomainSuggestion], Error>? = nil) {
        self.freeDomainsResult = freeDomainsResult
        self.paidDomainsResult = paidDomainsResult
        super.init(sessionManager: ServiceLocator.stores.sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? DomainAction {
            if case let .loadFreeDomainSuggestions(_, completion) = action {
                if let freeDomainsResult {
                    completion(freeDomainsResult)
                }
            } else if case let .loadPaidDomainSuggestions(_, completion) = action {
                if let paidDomainsResult {
                    completion(paidDomainsResult)
                }
            }
        }
    }
}

struct DomainSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty query state.
            DomainSelectorView<FreeDomainSelectorDataProvider, FreeDomainSuggestionViewModel>(
                viewModel:
                        .init(initialSearchTerm: "",
                              dataProvider: FreeDomainSelectorDataProvider(
                                stores: DomainSelectorViewStores()
                              )),
                onDomainSelection: { _ in },
                onSupport: {}
            )
            // Results state for free domains.
            DomainSelectorView<FreeDomainSelectorDataProvider, FreeDomainSuggestionViewModel>(
                viewModel:
                        .init(initialSearchTerm: "",
                              dataProvider: FreeDomainSelectorDataProvider(
                                stores: DomainSelectorViewStores(freeDomainsResult: .success([
                                    .init(name: "grapefruitsmoothie.com", isFree: true),
                                    .init(name: "fruitsmoothie.com", isFree: true),
                                    .init(name: "grapefruitsmoothiee.com", isFree: true),
                                    .init(name: "freesmoothieeee.com", isFree: true),
                                    .init(name: "greatfruitsmoothie1.com", isFree: true),
                                    .init(name: "tropicalsmoothie.com", isFree: true)
                                ]))
                              )),
                onDomainSelection: { _ in },
                onSupport: {}
            )
            // Results state for paid domains.
            DomainSelectorView<PaidDomainSelectorDataProvider, PaidDomainSuggestionViewModel>(
                viewModel:
                        .init(initialSearchTerm: "fruit",
                              dataProvider: PaidDomainSelectorDataProvider(
                                stores: DomainSelectorViewStores(paidDomainsResult: .success([
                                    .init(productID: 1,
                                          supportsPrivacy: true,
                                          name: "grapefruitsmoothie.com",
                                          term: "year",
                                          cost: "NT$154.00"),
                                    .init(productID: 2,
                                          supportsPrivacy: true,
                                          name: "fruitsmoothie.com",
                                          term: "year",
                                          cost: "NT$610.00",
                                          saleCost: "NT$154.00")
                                ]))
                              )),
                onDomainSelection: { _ in },
                onSupport: {}
            )
            // Error state.
            DomainSelectorView<FreeDomainSelectorDataProvider, FreeDomainSuggestionViewModel>(
                viewModel:
                        .init(initialSearchTerm: "test",
                              dataProvider:
                                FreeDomainSelectorDataProvider(
                                    stores: DomainSelectorViewStores(freeDomainsResult:
                                            .failure(DotcomError.unknown(code: "invalid_query",
                                                                         message: "Domain searches must contain a word with the following characters.")
                                    )))),
                              onDomainSelection: { _ in },
                              onSupport: {}
            )
            // Loading state.
            DomainSelectorView<FreeDomainSelectorDataProvider, FreeDomainSuggestionViewModel>(
                viewModel:
                        .init(initialSearchTerm: "",
                              dataProvider: FreeDomainSelectorDataProvider(
                                stores: DomainSelectorViewStores()
                              )),
                onDomainSelection: { _ in },
                onSupport: {}
            )
        }
    }
}

#endif
