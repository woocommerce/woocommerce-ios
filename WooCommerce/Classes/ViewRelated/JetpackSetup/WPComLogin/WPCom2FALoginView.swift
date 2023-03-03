import SwiftUI

/// View for 2FA login screen of the custom WPCom login flow for Jetpack setup.
struct WPCom2FALoginView: View {
    @ObservedObject private var viewModel: WPCom2FALoginViewModel
    @FocusState private var isFieldFocused: Bool
    @State private var isPrimaryButtonLoading = false
    @State private var isSMSRequestInProgress = false

    /// The closure to be triggered when the Install Jetpack button is tapped.
    private let onSubmit: (String) async -> Void

    /// The closure to be triggered when the Text me a code button is tapped.
    private let onSMSRequest: () async -> Void

    init(viewModel: WPCom2FALoginViewModel,
         onSubmit: @escaping (String) async -> Void,
         onSMSRequest: @escaping () async -> Void) {
        self.viewModel = viewModel
        self.onSubmit = onSubmit
        self.onSMSRequest = onSMSRequest
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.blockVerticalPadding) {
                JetpackInstallHeaderView()

                // title and description
                VStack(alignment: .leading, spacing: Constants.contentVerticalSpacing) {
                    Text(viewModel.titleString)
                        .largeTitleStyle()
                    Text(Localization.subtitleString)
                        .subheadlineStyle()
                }

                // Verification field
                AccountCreationFormFieldView(viewModel: .init(
                    header: "",
                    placeholder: Localization.verificationCode,
                    keyboardType: .asciiCapableNumberPad,
                    text: $viewModel.verificationCode,
                    isSecure: true,
                    errorMessage: nil,
                    isFocused: isFieldFocused
                ))
                .focused($isFieldFocused)

                Button(action: {
                    Task { @MainActor in
                        isSMSRequestInProgress = true
                        await onSMSRequest()
                        isSMSRequestInProgress = false
                    }
                }, label: {
                    if isSMSRequestInProgress {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Text(Localization.textMeACode)
                            .linkStyle()
                    }
                })
                Spacer()
            }
            .padding(Constants.contentPadding)
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                // Primary CTA
                Button(viewModel.titleString) {
                    Task { @MainActor in
                        isPrimaryButtonLoading = true
                        await onSubmit(viewModel.verificationCode)
                        isPrimaryButtonLoading = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPrimaryButtonLoading))
                .disabled(viewModel.verificationCode.isEmpty)
            }
            .padding(Constants.contentPadding)
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension WPCom2FALoginView {
    enum Constants {
        static let blockVerticalPadding: CGFloat = 32
        static let contentVerticalSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 16
    }

    enum Localization {
        static let subtitleString = NSLocalizedString(
            "Almost there! Please enter the verification code from your Authentication app",
            comment: "Instruction on the WPCom 2FA login screen of the Jetpack setup flow")
        static let verificationCode = NSLocalizedString(
            "Verification code",
            comment: "Placeholder for the 2FA code field on the WPCom 2FA login screen of the Jetpack setup flow."
        )
        static let textMeACode = NSLocalizedString(
            "Text me a code instead",
            comment: "Button to request 2FA code via SMS on the WPCom 2FA login screen of the Jetpack setup flow."
        )
    }
}

struct WPCom2FALoginView_Previews: PreviewProvider {
    static var previews: some View {
        WPCom2FALoginView(viewModel: .init(requiresConnectionOnly: true),
                          onSubmit: { _ in },
                           onSMSRequest: {})
    }
}
