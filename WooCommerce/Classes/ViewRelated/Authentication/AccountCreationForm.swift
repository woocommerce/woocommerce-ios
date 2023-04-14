import SwiftUI
import enum WordPressAuthenticator.SignInSource
import struct WordPressAuthenticator.NavigateToEnterAccount
import enum Yosemite.CreateAccountError

/// Hosting controller that wraps an `AccountCreationForm`.
final class AccountCreationFormHostingController: UIHostingController<AccountCreationForm> {
    private let analytics: Analytics
    private let signInSource: SignInSource
    private let completion: () -> Void

    init(field: AccountCreationForm.Field = .email,
         viewModel: AccountCreationFormViewModel,
         signInSource: SignInSource,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping () -> Void) {
        self.analytics = analytics
        self.signInSource = signInSource
        self.completion = completion
        super.init(rootView: AccountCreationForm(field: field, viewModel: viewModel))

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

        rootView.emailSubmissionHandler = { [weak self] email, isExisting in
            self?.handleEmailSubmission(email: email, isExisting: isExisting)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleEmailSubmission(email: String, isExisting: Bool) {
        guard !isExisting else {
            /// Navigates to login with the existing email address.
            let command = NavigateToEnterAccount(signInSource: signInSource, email: email)
            command.execute(from: self)
            return
        }
        /// Navigates to password field for account creation
        let viewModel = AccountCreationFormViewModel(email: email)
        let passwordView = AccountCreationFormHostingController(field: .password,
                                                                viewModel: viewModel,
                                                                signInSource: signInSource,
                                                                completion: completion)
        navigationController?.show(passwordView, sender: nil)
    }
}

/// A form that allows the user to create a WPCOM account with an email and password.
struct AccountCreationForm: View {
    enum Field: Equatable {
        case email
        case password
    }

    /// Triggered when the account is created and the app is authenticated.
    var completion: (() -> Void) = {}

    /// Triggered when the user taps on the login CTA.
    var loginButtonTapped: (() -> Void) = {}

    /// Triggered when the user submits an email address.
    var emailSubmissionHandler: ((_ email: String, _ isExisting: Bool) -> Void) = { _, _ in }

    @ObservedObject private var viewModel: AccountCreationFormViewModel

    @State private var isPerformingTask = false
    @State private var tosURL: URL?

    @FocusState private var isFocused: Bool

    private let field: Field

    private var isSubmitButtonDisabled: Bool {
        switch field {
        case .email:
            return !viewModel.isEmailValid || isPerformingTask
        case .password:
            return !viewModel.isPasswordValid || isPerformingTask
        }
    }

    init(field: Field, viewModel: AccountCreationFormViewModel) {
        self.viewModel = viewModel
        self.field = field
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
                // Header.
                VStack(alignment: .leading, spacing: Layout.horizontalSpacing) {
                    // Title label.
                    Text(field == .email ? Localization.title : Localization.titleForPassword)
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
                    .renderedIf(field == .email)

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
                    .renderedIf(field == .password)

                    // Terms of Service link.
                    AttributedText(tosAttributedText, enablesLinkUnderline: true)
                        .attributedTextLinkColor(Color(.secondaryLabel))
                        .environment(\.customOpenURL) { url in
                            tosURL = url
                        }
                        .safariSheet(url: $tosURL)
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
                        do {
                            try await viewModel.createAccount()
                            completion()
                        } catch CreateAccountError.emailExists {
                            emailSubmissionHandler(viewModel.email, true)
                        } catch CreateAccountError.invalidPassword where field == .email {
                            emailSubmissionHandler(viewModel.email, false)
                        } catch {
                            // No-op
                        }
                        isPerformingTask = false
                    }
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: isPerformingTask))
                .disabled(isSubmitButtonDisabled)
                .padding()
            }
            .background(Color(uiColor: .systemBackground))
        }
    }
}

private extension AccountCreationForm {
    var tosAttributedText: NSAttributedString {
        let result = NSMutableAttributedString(
            string: .localizedStringWithFormat(Localization.tosFormat, Localization.tos),
            attributes: [
                .foregroundColor: UIColor.secondaryLabel,
                .font: UIFont.caption1
            ]
        )
        result.replaceFirstOccurrence(
            of: Localization.tos,
            with: NSAttributedString(
                string: Localization.tos,
                attributes: [
                    .font: UIFont.caption1,
                    .link: Constants.tosURL,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
            ))
        return result
    }

    enum Constants {
        static let tosURL = WooConstants.URLs.termsOfService.asURL()
    }

    enum Localization {
        static let title = NSLocalizedString("Get started in minutes", comment: "Title for the account creation form.")
        static let titleForPassword = NSLocalizedString("Create your password", comment: "Title for the account creation form to create new password.")
        static let subtitle = NSLocalizedString("First, let’s create your account.", comment: "Subtitle for the account creation form.")
        static let loginButtonTitle = NSLocalizedString("Log in", comment: "Title of the login button on the account creation form.")
        static let emailFieldTitle = NSLocalizedString("Your email address", comment: "Title of the email field on the account creation form.")
        static let emailFieldPlaceholder = NSLocalizedString("Email address", comment: "Placeholder of the email field on the account creation form.")
        static let passwordFieldTitle = NSLocalizedString("Choose a password", comment: "Title of the password field on the account creation form.")
        static let passwordFieldPlaceholder = NSLocalizedString("Password", comment: "Placeholder of the password field on the account creation form.")
        static let tosFormat = NSLocalizedString("By continuing, you agree to our %1$@.", comment: "Terms of service format on the account creation form.")
        static let tos = NSLocalizedString("Terms of Service", comment: "Terms of service link on the account creation form.")
        static let submitButtonTitle = NSLocalizedString("Continue", comment: "Title of the submit button on the account creation form.")
    }

    enum Layout {
        static let verticalSpacing: CGFloat = 40
        static let verticalSpacingBetweenFields: CGFloat = 16
        static let horizontalSpacing: CGFloat = 16
    }
}

struct AccountCreationForm_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationForm(field: .email, viewModel: .init())
            .preferredColorScheme(.light)

        AccountCreationForm(field: .password, viewModel: .init())
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.xxxLarge)
    }
}
