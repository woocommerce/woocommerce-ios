import SwiftUI
import enum WordPressAuthenticator.SignInSource
import struct WordPressAuthenticator.NavigateToEnterAccount

/// Hosting controller that wraps an `AccountCreationForm`.
final class AccountCreationEmailFormHostingController: UIHostingController<AccountCreationEmailForm> {
    private let analytics: Analytics

    init(viewModel: AccountCreationEmailFormViewModel,
         signInSource: SignInSource,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping (String) -> Void) {
        self.analytics = analytics
        super.init(rootView: AccountCreationEmailForm(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController.
        rootView.completion = { email in
            completion(email)
        }

        rootView.loginButtonTapped = { [weak self] in
            guard let self else { return }

            self.analytics.track(event: .StoreCreation.signupFormLoginTapped())

            let command = NavigateToEnterAccount(signInSource: signInSource)
            command.execute(from: self)
        }

        rootView.existingEmailHandler = { email in
            let command = NavigateToEnterAccount(signInSource: signInSource, email: email)
            command.execute(from: self)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A form that allows the user to create a WPCOM account with an email and password.
struct AccountCreationEmailForm: View {

    /// Triggered when the account is created and the app is authenticated.
    var completion: ((String) -> Void) = { _ in }

    /// Triggered when the user taps on the login CTA.
    var loginButtonTapped: (() -> Void) = {}

    /// Triggered when the user enters an email that is associated with an existing WPCom account.
    var existingEmailHandler: ((String) -> Void) = { _ in }

    @ObservedObject private var viewModel: AccountCreationEmailFormViewModel

    @State private var isPerformingTask = false

    @FocusState private var isFocused: Bool

    init(viewModel: AccountCreationEmailFormViewModel) {
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
                    // Email field.
                    AuthenticationFormFieldView(viewModel: .init(header: Localization.emailFieldTitle,
                                                                  placeholder: Localization.emailFieldPlaceholder,
                                                                  keyboardType: .emailAddress,
                                                                  text: $viewModel.email,
                                                                  isSecure: false,
                                                                  errorMessage: viewModel.emailErrorMessage,
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
                        let accountExists = await viewModel.checkIfWPComAccountExists()
                        if accountExists {
                            existingEmailHandler(viewModel.email)
                        } else {
                            completion(viewModel.email)
                        }
                        isPerformingTask = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPerformingTask))
                .disabled(!viewModel.isEmailValid || isPerformingTask)
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension AccountCreationEmailForm {
    enum Localization {
        static let title = NSLocalizedString("Get started in minutes", comment: "Title for the account creation form.")
        static let subtitle = NSLocalizedString("First, let’s create your account.", comment: "Subtitle for the account creation form.")
        static let loginButtonTitle = NSLocalizedString("Log in", comment: "Title of the login button on the account creation form.")
        static let emailFieldTitle = NSLocalizedString("Your email address", comment: "Title of the email field on the account creation form.")
        static let emailFieldPlaceholder = NSLocalizedString("Email address", comment: "Placeholder of the email field on the account creation form.")
        static let submitButtonTitle = NSLocalizedString("Continue", comment: "Title of the submit button on the account creation form.")
    }

    enum Layout {
        static let verticalSpacing: CGFloat = 40
        static let verticalSpacingBetweenFields: CGFloat = 16
        static let horizontalSpacing: CGFloat = 16
    }
}

struct AccountCreationEmailForm_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationEmailForm(viewModel: .init())
            .preferredColorScheme(.light)

        AccountCreationEmailForm(viewModel: .init())
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.xxxLarge)
    }
}
