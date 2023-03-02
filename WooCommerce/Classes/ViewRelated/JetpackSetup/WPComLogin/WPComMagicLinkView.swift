import SwiftUI

/// Hosting controller for `WPComMagicLinkView`
final class WPComMagicLinkHostingController: UIHostingController<WPComMagicLinkView> {

    init(email: String, requiresConnectionOnly: Bool, onOpenMail: @escaping () -> Void) {
        let viewModel = WPComMagicLinkViewModel(email: email, requiresConnectionOnly: requiresConnectionOnly)
        super.init(rootView: WPComMagicLinkView(viewModel: viewModel, onOpenMail: onOpenMail))
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTransparentNavigationBar()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.cancel, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }
}

private extension WPComMagicLinkHostingController {
    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the site credential login screen")
    }
}


// The magic link screen for the WPCom authentication flow for Jetpack setup.
//
struct WPComMagicLinkView: View {
    private let viewModel: WPComMagicLinkViewModel
    private let onOpenMail: () -> Void

    init(viewModel: WPComMagicLinkViewModel, onOpenMail: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onOpenMail = onOpenMail
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title
                HStack {
                    Text(viewModel.titleString)
                        .largeTitleStyle()
                    Spacer()
                }

                Spacer()

                // Image and instructions
                VStack(spacing: Constants.contentVerticalSpacing) {
                    Image(uiImage: .emailImage)
                        .padding(.bottom)
                    Text(Localization.checkYourEmail)
                        .headlineStyle()
                    AttributedText(viewModel.instructionString)
                }

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(Localization.openMail) {
                    onOpenMail()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension WPComMagicLinkView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let openMail = NSLocalizedString(
            "Open Mail",
            comment: "Title for the CTA on the magic link screen of the WPCom login flow during Jetpack setup"
        )
        static let checkYourEmail = NSLocalizedString(
            "Check your email on this device!",
            comment: "Message on the magic link screen of the WPCom login flow during Jetpack setup"
        )
    }
}

struct WPComMagicLinkView_Previews: PreviewProvider {
    static var previews: some View {
        WPComMagicLinkView(viewModel: .init(email: "test@example.com", requiresConnectionOnly: true)) {}
    }
}
