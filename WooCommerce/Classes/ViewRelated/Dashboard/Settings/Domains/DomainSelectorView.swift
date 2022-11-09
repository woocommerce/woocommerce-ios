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

        navigationItem.rightBarButtonItem = .init(title: Localization.skipButtonTitle, style: .plain, target: self, action: #selector(skipButtonTapped))

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear

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
        static let skipButtonTitle = NSLocalizedString("Skip", comment: "Navigation bar button on the domain selector screen to skip domain selection.")
    }
}

/// Allows the user to search for a domain and then select one to continue.
struct DomainSelectorView: View {
    /// Set in the hosting controller.
    var onDomainSelection: ((String) -> Void) = { _ in }

    /// View model to drive the view.
    @ObservedObject var viewModel: DomainSelectorViewModel

    /// Currently selected domain name.
    /// If this property is kept in the view model, a SwiftUI error appears `Publishing changes from within view updates`
    /// when a domain row is selected.
    @State var selectedDomainName: String?

    var body: some View {
        ScrollableVStack(alignment: .leading) {
            // Header labels.
            VStack(alignment: .leading, spacing: Layout.spacingBetweenTitleAndSubtitle) {
                Text(Localization.title)
                    .titleStyle()
                Text(Localization.subtitle)
                    .foregroundColor(Color(.secondaryLabel))
                    .bodyStyle()
            }
            .padding(.horizontal, Layout.defaultHorizontalPadding)

            SearchHeader(filterText: $viewModel.searchTerm,
                         filterPlaceholder: Localization.searchPlaceholder)
            .padding(.horizontal, Layout.defaultHorizontalPadding)

            Text(Localization.suggestionsHeader)
                .foregroundColor(Color(.secondaryLabel))
                .bodyStyle()
                .padding(.horizontal, Layout.defaultHorizontalPadding)

            List {
                ForEach(viewModel.domainRows) { rowViewModel in
                    Button {
                        selectedDomainName = rowViewModel.name
                    } label: {
                        DomainRowView(viewModel: rowViewModel,
                                      isSelected: rowViewModel.name == selectedDomainName)
                    }
                }
            }.listStyle(.inset)

            if let selectedDomainName {
                Button(Localization.continueButtonTitle) {
                    onDomainSelection(selectedDomainName)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

private extension DomainSelectorView {
    enum Layout {
        static let spacingBetweenTitleAndSubtitle: CGFloat = 16
        static let defaultHorizontalPadding: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString("Choose a domain", comment: "Title of the domain selector.")
        static let subtitle = NSLocalizedString(
            "This is where people will find you on the Internet. Don't worry, you can change it later.",
            comment: "Subtitle of the domain selector.")
        static let searchPlaceholder = NSLocalizedString("Type to get suggestions", comment: "Placeholder of the search text field on the domain selector.")
        static let suggestionsHeader = NSLocalizedString("SUGGESTIONS", comment: "Header label of the domain suggestions on the domain selector.")
        static let continueButtonTitle = NSLocalizedString("Continue", comment: "Title of the button to continue with a selected domain.")
    }
}

struct DomainSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        DomainSelectorView(viewModel: .init())
    }
}
