import SwiftUI
import enum WordPressAuthenticator.SignInSource
import Yosemite

final class WooRestAPIAuthenticationFormHostingController: UIHostingController<WooRestAPIAuthenticationForm> {
    private let analytics: Analytics

    init(viewModel: WooRestAPIAuthenticationFormViewModel,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping (_ credentials: WooRestAPICredentials) -> Void) {
        self.analytics = analytics
        super.init(rootView: WooRestAPIAuthenticationForm(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController.
        rootView.completion = { credentials in
            completion(credentials)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct WooRestAPIAuthenticationForm: View {
    private enum Field: Hashable {
        case siteURL
        case consumerKey
        case consumerSecret
    }

    var completion: ((_ credentials: WooRestAPICredentials) -> Void) = { _ in }

    @ObservedObject private var viewModel: WooRestAPIAuthenticationFormViewModel

    @FocusState private var focusedField: Field?

    init(viewModel: WooRestAPIAuthenticationFormViewModel) {
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
                }

                // Form fields.
                VStack(spacing: Layout.verticalSpacingBetweenFields) {
                    // Site URL field.
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.siteAddressFieldTitle,
                                                                  placeholder: Localization.siteAddressFieldPlaceholder,
                                                                  keyboardType: .URL,
                                                                  text: $viewModel.siteAddress,
                                                                  isSecure: false,
                                                                  errorMessage: viewModel.siteAddressErrorMessage,
                                                                  isFocused: focusedField == .siteURL))
                    .focused($focusedField, equals: .siteURL)

                    // Consumer Key field.
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.consumerKeyFieldTitle,
                                                                  placeholder: Localization.consumerKeyFieldPlaceholder,
                                                                  keyboardType: .default,
                                                                  text: $viewModel.consumerKey,
                                                                  isSecure: false,
                                                                  errorMessage: viewModel.siteAddressErrorMessage,
                                                                  isFocused: focusedField == .consumerKey))
                    .focused($focusedField, equals: .consumerKey)

                    // Consumer Secret field.
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.consumerSecretFieldTitle,
                                                                  placeholder: Localization.consumerSecretFieldPlaceholder,
                                                                  keyboardType: .default,
                                                                  text: $viewModel.consumerSecret,
                                                                  isSecure: false,
                                                                  errorMessage: viewModel.siteAddressErrorMessage,
                                                                  isFocused: focusedField == .consumerSecret))
                    .focused($focusedField, equals: .consumerSecret)
                }

                // CTA to submit the form.
                Button(Localization.submitButtonTitle) {
                    completion(viewModel.credentials!)
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: false))
                .disabled(viewModel.credentials == nil)
            }
            .padding(.init(top: 0, leading: Layout.horizontalSpacing, bottom: 0, trailing: Layout.horizontalSpacing))
        }
    }
}

private extension WooRestAPIAuthenticationForm {

    enum Constants {
        static let tosURL = WooConstants.URLs.termsOfService.asURL()
    }

    enum Localization {
        static let title = NSLocalizedString("Login using REST API keys", comment: "Title for the account creation form.")
        static let siteAddressFieldTitle = NSLocalizedString("Your site address", comment: "Title of the email field")
        static let siteAddressFieldPlaceholder = NSLocalizedString("Site address", comment: "Placeholder of the email field")

        static let consumerKeyFieldTitle = NSLocalizedString("Consumer key", comment: "Title of the Consumer key field")
        static let consumerKeyFieldPlaceholder = NSLocalizedString("Consumer key", comment: "Placeholder of the Consumer key field")

        static let consumerSecretFieldTitle = NSLocalizedString("Consumer secret", comment: "Title of the Consumer secret field")
        static let consumerSecretFieldPlaceholder = NSLocalizedString("Consumer secret", comment: "Placeholder of the Consumer secret field")

        static let submitButtonTitle = NSLocalizedString("Login", comment: "Title of the submit button")
    }

    enum Layout {
        static let verticalSpacing: CGFloat = 40
        static let verticalSpacingBetweenFields: CGFloat = 16
        static let horizontalSpacing: CGFloat = 16
    }
}

struct WooRestAPIAuthenticationForm_Previews: PreviewProvider {
    static var previews: some View {
        WooRestAPIAuthenticationForm(viewModel: .init())
            .preferredColorScheme(.light)

        WooRestAPIAuthenticationForm(viewModel: .init())
            .preferredColorScheme(.dark)
            .dynamicTypeSize(.xxxLarge)
    }
}
