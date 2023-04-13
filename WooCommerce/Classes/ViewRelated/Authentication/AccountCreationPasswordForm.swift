import SwiftUI
import enum WordPressAuthenticator.SignInSource
import struct WordPressAuthenticator.NavigateToEnterAccount

/// Hosting controller that wraps an `AccountCreationForm`.
final class AccountCreationPasswordFormHostingController: UIHostingController<AccountCreationPasswordForm> {
    private let analytics: Analytics

    init(viewModel: AccountCreationPasswordFormViewModel,
         signInSource: SignInSource,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping () -> Void) {
        self.analytics = analytics
        super.init(rootView: AccountCreationPasswordForm(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController.
        rootView.completion = {
            completion()
        }

        rootView.loginButtonTapped = { [weak self] in
            guard let self else { return }

            self.analytics.track(event: .StoreCreation.signupFormLoginTapped())

            let command = NavigateToEnterAccount(signInSource: signInSource)
            command.execute(from: self)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A form that allows the user to enter the password to create a new WPCOM account.
struct AccountCreationPasswordForm: View {

    /// Triggered when the account is created and the app is authenticated.
    var completion: (() -> Void) = {}

    /// Triggered when the user taps on the login CTA.
    var loginButtonTapped: (() -> Void) = {}

    @ObservedObject private var viewModel: AccountCreationPasswordFormViewModel

    @State private var isPerformingTask = false

    @FocusState private var isFocused: Bool

    init(viewModel: AccountCreationPasswordFormViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                // Header.
                VStack(alignment: .leading, spacing: Layout.horizontalSpacing) {
                    // Title label.
                    Text(Localization.title)
                        .largeTitleStyle()
                    VStack(alignment: .leading, spacing: 0) {
                        // Subtitle label.
                        Text(Localization.subtitle)
                            .foregroundColor(Color(.secondaryLabel))
                            .bodyStyle()
                    }
                }

                // Form fields.
                VStack(spacing: Layout.verticalSpacingBetweenFields) {

                    // Password field.
                    AuthenticationFormFieldView(viewModel: .init(header: Localization.passwordFieldTitle,
                                                                  placeholder: Localization.passwordFieldPlaceholder,
                                                                  keyboardType: .default,
                                                                  text: $viewModel.password,
                                                                  isSecure: true,
                                                                  errorMessage: viewModel.passwordErrorMessage,
                                                                  isFocused: isFocused))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)
                    .disabled(isPerformingTask)

                    // Terms of Service link.
                    AccountCreationTOSView()
                }
            }
            .padding(.init(top: 0, leading: Layout.horizontalSpacing, bottom: 0, trailing: Layout.horizontalSpacing))
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.loginButtonTitle, action: loginButtonTapped)
                    .buttonStyle(TextButtonStyle())
                    .disabled(isPerformingTask)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // CTA to submit the form.
            VStack {
                Button(Localization.submitButtonTitle.localizedCapitalized) {
                    Task { @MainActor in
                        isPerformingTask = true
                        let createAccountCompleted = (try? await viewModel.createAccount()) != nil
                        if createAccountCompleted {
                            completion()
                        }
                        isPerformingTask = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPerformingTask))
                .disabled(!viewModel.isPasswordValid || isPerformingTask)
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension AccountCreationPasswordForm {
    enum Localization {
        static let title = NSLocalizedString("Create your password", comment: "Title for the account creation password form.")
        static let subtitle = NSLocalizedString("First, let’s create your account.", comment: "Subtitle for the account creation form.")
        static let loginButtonTitle = NSLocalizedString("Log in", comment: "Title of the login button on the account creation form.")
        static let passwordFieldTitle = NSLocalizedString("Choose a password", comment: "Title of the password field on the account creation form.")
        static let passwordFieldPlaceholder = NSLocalizedString("Password", comment: "Placeholder of the password field on the account creation form.")
        static let submitButtonTitle = NSLocalizedString("Continue", comment: "Title of the submit button on the account creation form.")
    }

    enum Layout {
        static let verticalSpacing: CGFloat = 40
        static let verticalSpacingBetweenFields: CGFloat = 16
        static let horizontalSpacing: CGFloat = 16
    }
}

struct AccountCreationPasswordForm_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationPasswordForm(viewModel: .init(email: "test@example.com"))
            .preferredColorScheme(.light)

        AccountCreationPasswordForm(viewModel: .init(email: "test@example.com"))
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.xxxLarge)
    }
}
