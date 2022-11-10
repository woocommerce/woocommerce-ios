import SwiftUI

/// Hosting controller that wraps the `DomainSelectorView` view.
final class DomainSelectorHostingController: UIHostingController<DomainSelectorView> {
    private let viewModel: DomainSelectorViewModel
    private let onDomainSelection: (String) -> Void
    private let onSkip: () -> Void

    /// - Parameters:
    ///   - viewModel: View model for the domain selector.
    ///   - onDomainSelection: Called when the user continues with a selected domain name.
    ///   - onSkip: Called when the user taps to skip domain selection.
    init(viewModel: DomainSelectorViewModel,
         onDomainSelection: @escaping (String) -> Void,
         onSkip: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDomainSelection = onDomainSelection
        self.onSkip = onSkip
        super.init(rootView: DomainSelectorView(viewModel: viewModel))

        rootView.onDomainSelection = { [weak self] domain in
            self?.onDomainSelection(domain)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSkipButton()
        configureNavigationBarAppearance()
    }
}

private extension DomainSelectorHostingController {
    func configureSkipButton() {
        navigationItem.rightBarButtonItem = .init(title: Localization.skipButtonTitle, style: .plain, target: self, action: #selector(skipButtonTapped))
    }

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
    @objc func skipButtonTapped() {
        onSkip()
    }
}

private extension DomainSelectorHostingController {
    enum Localization {
        static let title = NSLocalizedString("Choose a domain", comment: "Title of the domain selector.")
        static let skipButtonTitle = NSLocalizedString("Skip", comment: "Navigation bar button on the domain selector screen to skip domain selection.")
    }
}

/// Allows the user to search for a domain and then select one to continue.
struct DomainSelectorView: View {
    /// Set in the hosting controller.
    var onDomainSelection: ((String) -> Void) = { _ in }

    /// View model to drive the view.
    @ObservedObject private(set) var viewModel: DomainSelectorViewModel

    /// Currently selected domain name.
    /// If this property is kept in the view model, a SwiftUI error appears `Publishing changes from within view updates`
    /// when a domain row is selected.
    @State private var selectedDomainName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading) {
                    // Header label.
                    Text(Localization.subtitle)
                        .foregroundColor(Color(.secondaryLabel))
                        .bodyStyle()
                        .padding(.horizontal, Layout.defaultHorizontalPadding)

                    // Search text field.
                    SearchHeader(filterText: $viewModel.searchTerm,
                                 filterPlaceholder: Localization.searchPlaceholder)
                    .padding(.horizontal, Layout.defaultHorizontalPadding)

                    // Results header.
                    Text(Localization.suggestionsHeader)
                        .foregroundColor(Color(.secondaryLabel))
                        .bodyStyle()
                        .padding(.horizontal, Layout.defaultHorizontalPadding)

                    // Domain suggestions.
                    if let placeholderImage = viewModel.placeholderImage {
                        Image(uiImage: placeholderImage)
                    } else if viewModel.isLoadingDomainSuggestions {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .padding(Layout.defaultPadding)
                    } else {
                        LazyVStack {
                            ForEach(viewModel.domains, id: \.self) { domain in
                                Button {
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

            // Continue button when a domain is selected.
            if let selectedDomainName {
                Divider()
                    .frame(height: Layout.dividerHeight)
                    .foregroundColor(Color(.separator))
                Button(Localization.continueButtonTitle) {
                    onDomainSelection(selectedDomainName)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(Layout.defaultPadding)
            }
        }
        .onChange(of: viewModel.isLoadingDomainSuggestions) { isLoadingDomainSuggestions in
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

final class DomainSelectorStores: DefaultStoresManager {
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
                          stores: DomainSelectorStores(result: nil)))
            // Results state.
            DomainSelectorView(viewModel:
                    .init(initialSearchTerm: "Fruit smoothie",
                          stores: DomainSelectorStores(result: .success([
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
                          stores: DomainSelectorStores(result: .failure(
                            DotcomError.unknown(code: "invalid_query",
                                                message: "Domain searches must contain a word with the following characters.")
                          ))))
            // Loading state.
            DomainSelectorView(viewModel:
                    .init(initialSearchTerm: "test",
                          stores: DomainSelectorStores(result: nil)))
        }
    }
}

#endif
