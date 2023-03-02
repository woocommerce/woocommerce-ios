import SwiftUI

// The magic link screen for the WPCom authentication flow for Jetpack setup.
//
struct WPComMagicLinkView: View {
    private let viewModel: WPComMagicLinkViewModel

    init(viewModel: WPComMagicLinkViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title
                Text(viewModel.titleString)
                    .largeTitleStyle()

                Spacer()

                // Image and instructions
                VStack(spacing: Constants.contentVerticalSpacing) {
                    Image(uiImage: .emailImage)
                        .padding(.bottom)
                    Text(Localization.checkYourEmail)
                        .headlineStyle()
                    Text(Localization.sentLink)
                }

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(Localization.openMail) {
                    // TODO
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
        static let sentLink = NSLocalizedString(
            "We just sent a magic link to %@",
            comment: "Instruction on the magic link screen of the WPCom login flow during Jetpack setup. " +
            "%@ is a submitted email address."
        )
    }
}

struct WPComMagicLinkView_Previews: PreviewProvider {
    static var previews: some View {
        WPComMagicLinkView(viewModel: .init(email: "test@example.com", requiresConnectionOnly: true))
    }
}
