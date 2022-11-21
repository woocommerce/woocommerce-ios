import SwiftUI

/// Hosting controller that wraps the `DomainSelectorView` view.
final class DomainSelectorHostingController: UIHostingController<DomainSelectorView> {
    private let viewModel: DomainSelectorViewModel
    private let onDomainSelection: (String) async -> Void

    /// - Parameters:
    ///   - viewModel: View model for the domain selector.
    ///   - onDomainSelection: Called when the user continues with a selected domain name.
    init(viewModel: DomainSelectorViewModel,
         onDomainSelection: @escaping (String) async -> Void) {
        self.viewModel = viewModel
        self.onDomainSelection = onDomainSelection
        super.init(rootView: DomainSelectorView(viewModel: viewModel))

        rootView.onDomainSelection = { [weak self] domain in
            await self?.onDomainSelection(domain)
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
        navigationItem.title = Localization.title

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }
}

private extension DomainSelectorHostingController {
    enum Localization {
        static let title = NSLocalizedString("Choose a domain", comment: "Title of the domain selector.")
    }
}

/// Allows the user to search for a domain and then select one to continue.
struct DomainSelectorView: View {
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
            VStack(alignment: .leading) {
                // Header label.
                Text(Localization.subtitle)
                    .foregroundColor(Color(.secondaryLabel))
                    .bodyStyle()
                    .padding(.horizontal, Layout.defaultHorizontalPadding)

                // Search text field.
                SearchHeader(text: $viewModel.searchTerm,
                             placeholder: Localization.searchPlaceholder,
                             customizations: .init(backgroundColor: .clear,
                                                   borderColor: .separator,
                                                   internalHorizontalPadding: 21,
                                                   internalVerticalPadding: 12))
                .focused($textFieldIsFocused)

                // Results header.
                Text(Localization.suggestionsHeader)
                    .foregroundColor(Color(.secondaryLabel))
                    .footnoteStyle()
                    .padding(.horizontal, Layout.defaultHorizontalPadding)

                if viewModel.searchTerm.isEmpty {
                    // Placeholder image when search query is empty.
                    HStack {
                        Spacer()
                        Image(uiImage: .domainSearchPlaceholderImage)
                        Spacer()
                    }
                } else if viewModel.isLoadingDomainSuggestions {
                    // Progress indicator when loading domain suggestions.
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    // Error message when there is an error loading domain suggestions.
                    Text(errorMessage)
                        .padding(Layout.defaultPadding)
                } else {
                    // Domain suggestions.
                    LazyVStack {
                        ForEach(viewModel.domains, id: \.self) { domain in
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
        static let spacingBetweenTitleAndSubtitle: CGFloat = 16
        static let defaultHorizontalPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let defaultPadding: EdgeInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
    }

    enum Localization {
        static let subtitle = NSLocalizedString(
            "This is where people will find you on the Internet. Don't worry, you can change it later.",
            comment: "Subtitle of the domain selector.")
        static let searchPlaceholder = NSLocalizedString("Type to get suggestions", comment: "Placeholder of the search text field on the domain selector.")
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
