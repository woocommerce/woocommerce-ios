import SwiftUI

/// Hosting controller that wraps the `DomainSelectorView` view.
final class DomainSelectorHostingController: UIHostingController<DomainSelectorView> {
    private let viewModel: DomainSelectorViewModel

    /// - Parameters:
    ///   - viewModel: View model for the domain selector.
    ///   - onDomainSelection: Called when the user continues with a selected domain name.
    init(viewModel: DomainSelectorViewModel,
         onDomainSelection: @escaping (String) async -> Void) {
        self.viewModel = viewModel
        super.init(rootView: DomainSelectorView(viewModel: viewModel))

        rootView.onDomainSelection = { domain in
            await onDomainSelection(domain)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarAppearance()
    }
}

private extension DomainSelectorHostingController {
    /// Shows a transparent navigation bar without a bottom border.
    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }
}

/// Allows the user to search for a domain and then select one to continue.
struct DomainSelectorView: View {
    /// The state of the main view below the fixed header.
    enum ViewState: Equatable {
        /// When loading domain suggestions.
        case loading
        /// Shown when the search query is empty.
        case placeholder
        /// When there is an error loading domain suggestions.
        case error(message: String)
        /// When domain suggestions are displayed.
        case results(domains: [String])
    }

    /// Set in the hosting controller.
    var onDomainSelection: ((String) async -> Void) = { _ in }

    /// View model to drive the view.
    @ObservedObject private var viewModel: DomainSelectorViewModel

    /// Currently selected domain name.
    /// If this property is kept in the view model, a SwiftUI error appears `Publishing changes from within view updates`
    /// when a domain row is selected.
    @State private var selectedDomainName: String?

    @State private var isWaitingForDomainSelectionCompletion: Bool = false

    @FocusState private var textFieldIsFocused: Bool

    init(viewModel: DomainSelectorViewModel) {
        self.viewModel = viewModel
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
                        ForEach(domains, id: \.self) { domain in
                            Button {
                                textFieldIsFocused = false
                                selectedDomainName = domain
                            } label: {
                                VStack(alignment: .leading) {
                                    DomainRowView(viewModel: .init(domainName: domain,
                                                                   searchQuery: viewModel.searchTerm,
                                                                   isSelected: domain == selectedDomainName))
                                    Divider()
                                        .frame(height: Layout.dividerHeight)
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
            if let selectedDomainName {
                VStack {
                    Divider()
                        .frame(height: Layout.dividerHeight)
                        .foregroundColor(Color(.separator))
                    Button(Localization.continueButtonTitle) {
                        Task { @MainActor in
                            isWaitingForDomainSelectionCompletion = true
                            await onDomainSelection(selectedDomainName)
                            isWaitingForDomainSelectionCompletion = false
                        }
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isWaitingForDomainSelectionCompletion))
                    .padding(Layout.defaultPadding)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: viewModel.isLoadingDomainSuggestions) { isLoadingDomainSuggestions in
            // Resets selected domain when loading domain suggestions.
            if isLoadingDomainSuggestions {
                selectedDomainName = nil
            }
        }
    }
}

private extension DomainSelectorView {
    enum Layout {
        static let defaultHorizontalPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
    }

    enum Localization {
        static let title = NSLocalizedString("Choose a domain", comment: "Title of the domain selector.")
        static let subtitle = NSLocalizedString(
            "This is where people will find you on the Internet. You can add another domain later.",
            comment: "Subtitle of the domain selector.")
        static let searchPlaceholder = NSLocalizedString("Type a name for your store", comment: "Placeholder of the search text field on the domain selector.")
        static let suggestionsHeader = NSLocalizedString("SUGGESTIONS", comment: "Header label of the domain suggestions on the domain selector.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title of the button to continue with a selected domain.")
    }
}

#if DEBUG

import Yosemite
import enum Networking.DotcomError

/// StoresManager that specifically handles `DomainAction` for `DomainSelectorView` previews.
final class DomainSelectorViewStores: DefaultStoresManager {
    private let result: Result<[FreeDomainSuggestion], Error>?

    init(result: Result<[FreeDomainSuggestion], Error>?) {
        self.result = result
        super.init(sessionManager: ServiceLocator.stores.sessionManager)
    }

    override func dispatch(_ action: Action) {
        if let action = action as? DomainAction {
            if case let .loadFreeDomainSuggestions(_, completion) = action {
                if let result {
                    completion(result)
                }
            }
        }
    }
}

struct DomainSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty query state.
            DomainSelectorView(viewModel:
                    .init(initialSearchTerm: "",
                          stores: DomainSelectorViewStores(result: nil)))
            // Results state.
            DomainSelectorView(viewModel:
                    .init(initialSearchTerm: "Fruit smoothie",
                          stores: DomainSelectorViewStores(result: .success([
                            .init(name: "grapefruitsmoothie.com", isFree: true),
                            .init(name: "fruitsmoothie.com", isFree: true),
                            .init(name: "grapefruitsmoothiee.com", isFree: true),
                            .init(name: "freesmoothieeee.com", isFree: true),
                            .init(name: "greatfruitsmoothie1.com", isFree: true),
                            .init(name: "tropicalsmoothie.com", isFree: true)
                          ]))))
            // Error state.
            DomainSelectorView(viewModel:
                    .init(initialSearchTerm: "test",
                          stores: DomainSelectorViewStores(result: .failure(
                            DotcomError.unknown(code: "invalid_query",
                                                message: "Domain searches must contain a word with the following characters.")
                          ))))
            // Loading state.
            DomainSelectorView(viewModel:
                    .init(initialSearchTerm: "test",
                          stores: DomainSelectorViewStores(result: nil)))
        }
    }
}

#endif
