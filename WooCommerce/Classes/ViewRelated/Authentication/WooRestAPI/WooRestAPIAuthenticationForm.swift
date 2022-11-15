import SwiftUI
import enum WordPressAuthenticator.SignInSource
import struct WordPressAuthenticator.NavigateToEnterAccount

final class WooRestAPIAuthenticationFormHostingController: UIHostingController<WooRestAPIAuthenticationForm> {
    private let analytics: Analytics

    init(viewModel: WooRestAPIAuthenticationFormViewModel,
         analytics: Analytics = ServiceLocator.analytics,
         completion: @escaping (_ siteURL: String) -> Void) {
        self.analytics = analytics
        super.init(rootView: WooRestAPIAuthenticationForm(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController.
        rootView.completion = { siteURL in
            completion(siteURL)
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct WooRestAPIAuthenticationForm: View {
    private enum Field: Hashable {
        case email
        case password
    }

    var completion: ((_ siteURL: String) -> Void) = { _ in }

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
                    // Email field.
                    AccountCreationFormFieldView(viewModel: .init(header: Localization.emailFieldTitle,
                                                                  placeholder: Localization.emailFieldPlaceholder,
                                                                  keyboardType: .emailAddress,
                                                                  text: $viewModel.siteAddress,
                                                                  isSecure: false,
                                                                  errorMessage: viewModel.siteAddressErrorMessage,
                                                                  isFocused: focusedField == .email))
                    .focused($focusedField, equals: .email)
                }

                // CTA to submit the form.
                Button(Localization.submitButtonTitle) {
                    completion(viewModel.siteAddress)
                }
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
        static let title = NSLocalizedString("Get started in minutes", comment: "Title for the account creation form.")
        static let emailFieldTitle = NSLocalizedString("Your email address", comment: "Title of the email field on the account creation form.")
        static let emailFieldPlaceholder = NSLocalizedString("Email address", comment: "Placeholder of the email field on the account creation form.")
        static let submitButtonTitle = NSLocalizedString("Get started", comment: "Title of the submit button on the account creation form.")
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
