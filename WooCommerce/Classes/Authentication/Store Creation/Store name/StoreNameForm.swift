import SwiftUI

/// Hosting controller that wraps the `StoreNameForm`.
final class StoreNameFormHostingController: UIHostingController<StoreNameForm> {
    private let onContinue: (String) -> Void
    private let onClose: () -> Void

    init(onContinue: @escaping (String) -> Void,
         onClose: @escaping () -> Void) {
        self.onContinue = onContinue
        self.onClose = onClose
        super.init(rootView: StoreNameForm())

        rootView.onContinue = { [weak self] storeName in
            self?.onContinue(storeName)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarAppearance()
    }

    /// Shows a transparent navigation bar without a bottom border and with a close button to dismiss.
    func configureNavigationBarAppearance() {
        addCloseNavigationBarButton(title: Localization.cancelButtonTitle,
                                    target: self,
                                    action: #selector(closeButtonTapped))
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .systemBackground

        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    @objc private func closeButtonTapped() {
        onClose()
    }
}

private extension StoreNameFormHostingController {
    enum Localization {
        static let cancelButtonTitle = NSLocalizedString("Cancel", comment: "Navigation bar button on the store name form to leave the store creation flow.")
    }
}

/// Allows the user to enter a store name during the store creation flow.
struct StoreNameForm: View {
    /// Set in the hosting controller.
    var onContinue: (String) -> Void = { _ in }

    @State private var name: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Top header label.
                        Text(Localization.topHeader)
                            .foregroundColor(Color(.secondaryLabel))
                            .footnoteStyle()

                        // Title label.
                        Text(Localization.title)
                            .fontWeight(.bold)
                            .titleStyle()

                        // Subtitle label.
                        Text(Localization.subtitle)
                            .foregroundColor(Color(.secondaryLabel))
                            .bodyStyle()
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        // Text field prompt label.
                        Text(Localization.textFieldPrompt)
                            .foregroundColor(Color(.label))
                            .bodyStyle()

                        // Store name text field.
                        TextField(Localization.textFieldPlaceholder, text: $name)
                            .font(.body)
                            .textFieldStyle(RoundedBorderTextFieldStyle(focused: false))
                            .focused()
                    }
                }
                .padding(Layout.contentPadding)
            }

            // Continue button.
            Button(Localization.continueButtonTitle) {
                onContinue(name)
            }
            .padding(Layout.defaultButtonPadding)
            .buttonStyle(PrimaryButtonStyle())
            .disabled(name.isEmpty)
        }
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension StoreNameForm {
    enum Layout {
        static let spacingBetweenSubtitleAndStoreInfo: CGFloat = 40
        static let spacingBetweenStoreNameAndDomain: CGFloat = 4
        static let defaultHorizontalPadding: CGFloat = 16
        static let dividerHeight: CGFloat = 1
        static let contentPadding: EdgeInsets = .init(top: 38, leading: 16, bottom: 16, trailing: 16)
        static let defaultButtonPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let storeInfoPadding: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let storeInfoCornerRadius: CGFloat = 8
    }

    enum Localization {
        static let topHeader = NSLocalizedString(
            "ABOUT YOUR STORE",
            comment: "Header label on the top of the store name form in the store creation flow."
        )
        static let title = NSLocalizedString(
            "What’s your store name?",
            comment: "Title label on the store name form in the store creation flow."
        )
        static let subtitle = NSLocalizedString(
            "Don’t worry you can always change it later.",
            comment: "Subtitle label on the store name form in the store creation flow."
        )
        static let textFieldPrompt = NSLocalizedString(
            "Store name",
            comment: "Text field prompt on the store name form in the store creation flow."
        )
        static let textFieldPlaceholder = NSLocalizedString(
            "Type a name for your store",
            comment: "Text field placeholder on the store name form in the store creation flow."
        )
        static let continueButtonTitle = NSLocalizedString(
            "Continue",
            comment: "Title of the button on the store creation store name form to continue."
        )
    }
}

struct StoreNameForm_Previews: PreviewProvider {
    static var previews: some View {
        StoreNameForm()
    }
}
