import SwiftUI
import Kingfisher

/// Screen for entering the password for a WPCom account during the Jetpack setup flow
/// This is presented for users authenticated with WPOrg credentials.
struct WPComPasswordLoginView: View {
    @FocusState private var isPasswordFieldFocused: Bool
    @ObservedObject private var viewModel: WPComPasswordLoginViewModel

    init(viewModel: WPComPasswordLoginViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // Title
                Text(viewModel.titleString)
                    .largeTitleStyle()

                // Avatar and email
                HStack(spacing: Constants.contentPadding) {
                    viewModel.avatarURL.map { url in
                        KFImage(url)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
                    }
                    Text(viewModel.email)
                    Spacer()
                }
                .padding(Constants.avatarPadding)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(.gray, lineWidth: 1)
                )

                // Password field
                AccountCreationFormFieldView(viewModel: .init(
                    header: Localization.passwordLabel,
                    placeholder: Localization.passwordPlaceholder,
                    keyboardType: .default,
                    text: $viewModel.password,
                    isSecure: true,
                    errorMessage: nil,
                    isFocused: isPasswordFieldFocused
                ))
                .focused($isPasswordFieldFocused)

                // Reset password button
                Button {
                    // TODO
                } label: {
                    Text(Localization.resetPassword)
                        .linkStyle()
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(Localization.primaryAction) {
                    // TODO
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.password.isEmpty)

                // Secondary CTA
                Button(Localization.secondaryAction) {
                    // TODO
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension WPComPasswordLoginView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
        static let avatarSize: CGFloat = 32
        static let avatarPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    }

    enum Localization {
        static let passwordLabel = NSLocalizedString(
            "Enter your WordPress.com password",
            comment: "Label for the password field on the WPCom password login screen of the Jetpack setup flow."
        )
        static let passwordPlaceholder = NSLocalizedString(
            "Enter password",
            comment: "Placeholder text for the password field on the WPCom password login screen of the Jetpack setup flow."
        )
        static let resetPassword = NSLocalizedString(
            "Reset your password",
            comment: "Button to reset password on the WPCom password login screen of the Jetpack setup flow."
        )
        static let primaryAction = NSLocalizedString(
            "Continue",
            comment: "Button to submit password on the WPCom password login screen of the Jetpack setup flow."
        )
        static let secondaryAction = NSLocalizedString(
            "Or Continue using Magic Link",
            comment: "Button to switch to magic link on the WPCom password login screen of the Jetpack setup flow."
        )
    }
}

struct WPComPasswordLoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPComPasswordLoginView(viewModel: .init(email: "test@example.com", requiresConnectionOnly: true))
    }
}
