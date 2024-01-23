import Foundation
import SwiftUI

/// Hosting Controller for the Support Form.
///
final class SupportFormHostingController: UIHostingController<SupportForm> {

    /// Custom notice presenter,
    ///
    private lazy var noticePresenter: NoticePresenter = {
        let presenter = DefaultNoticePresenter()
        presenter.presentingViewController = navigationController ?? self
        return presenter
    }()


    init(viewModel: SupportFormViewModel) {
        super.init(rootView: SupportForm(viewModel: viewModel))
        handleSupportRequestCompletion(viewModel: viewModel)
        hidesBottomBarWhenPushed = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        createZendeskIdentity()
    }

    /// Creates the Zendesk Identity if needed.
    /// If it fails, it dismisses the view and informs the user.
    ///
    func createZendeskIdentity() {
        // TODO: We should consider refactoring this to present the email alert using SwiftUI.
        ZendeskProvider.shared.createIdentity(presentIn: self) { [weak self] identityCreated in
            if !identityCreated {
                self?.logIdentityErrorAndPopBack()
            }
        }
    }

    /// Registers a completion block on the view model to properly show alerts and notices.
    ///
    func handleSupportRequestCompletion(viewModel: SupportFormViewModel) {
        viewModel.onDismiss = { [weak self] in
            self?.dismissView()
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SupportFormHostingController {

    /// Informs user about identity error and pop back
    ///
    func logIdentityErrorAndPopBack() {
        let notice = Notice(title: Localization.badIdentityError, feedbackType: .error)
        noticePresenter.enqueue(notice: notice)

        dismissView()
        DDLogError("⛔️ Zendesk Identity could not be created.")
    }
}

private extension SupportFormHostingController {
    enum Localization {
        static let badIdentityError = NSLocalizedString("Sorry, we cannot create support requests right now, please try again later.",
                                                        comment: "Error message when the app can't create a zendesk identity.")
    }
}

/// Support Form Main View.
/// TODO: Add Landscape & Big Fonts support
///
struct SupportForm: View {

    /// Main ViewModel to drive the view.
    ///
    @StateObject var viewModel: SupportFormViewModel

    var body: some View {
        VStack(spacing: .zero) {

            // Scrollable Form
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.sectionSpacing) {

                    Text(Localization.iNeedHelp.uppercased())
                        .footnoteStyle()
                        .padding([.horizontal, .top])

                    // Area List
                    VStack(alignment: .leading, spacing: .zero) {
                        ForEach(viewModel.areas.indexed(), id: \.0.self) { index, area in
                            HStack(alignment: .center, spacing: Layout.radioButtonSpacing) {
                                // Radio-Button emulation
                                Circle()
                                    .stroke(Color(.separator), lineWidth: Layout.radioButtonBorderWidth)
                                    .frame(width: Layout.radioButtonSize, height: Layout.radioButtonSize)
                                    .background(
                                        // Use a clear color for non-selected radio buttons.
                                        Circle()
                                            .fill( viewModel.isAreaSelected(area) ? Color(.accent) : .clear)
                                            .padding(Layout.radioButtonBorderWidth)
                                    )

                                Text(area.title)
                                    .headlineStyle()
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading) // Needed to make tap area the whole width
                            .background(Color(.listForeground(modal: false)))
                            .onTapGesture {
                                viewModel.selectArea(area)
                            }

                            Divider()
                                .padding(.leading)
                                .renderedIf(index < viewModel.areas.count - 1) // Don't render the last divider
                        }
                    }
                    .cornerRadius(Layout.cornerRadius)
                    .padding(.bottom)

                    // Info Section
                    VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                        Text(Localization.letsGetItSorted)
                            .headlineStyle()

                        Text(Localization.tellUsInfo)
                            .subheadlineStyle()
                    }

                    // Subject Text Field
                    VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                        Text(Localization.subject)
                            .foregroundColor(Color(.text))
                            .subheadlineStyle()

                        TextField("", text: $viewModel.subject)
                            .bodyStyle()
                            .padding(insets: Layout.subjectInsets)
                            .background(Color(.listForeground(modal: false)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                            )
                    }

                    // Description Text Editor
                    VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                        Text(Localization.message)
                            .foregroundColor(Color(.text))
                            .subheadlineStyle()

                        TextEditor(text: $viewModel.description)
                            .bodyStyle()
                            .frame(minHeight: Layout.minimuEditorSize)
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius).stroke(Color(.separator))
                            )
                    }
                }
                .padding()
            }

            // Submit Request Footer
            VStack() {
                Divider()

                Button {
                    viewModel.submitSupportRequest()
                } label: {
                    Text(Localization.submitRequest)
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.showLoadingIndicator))
                .disabled(viewModel.submitButtonDisabled)
                .padding()
            }
            .background(Color(.listForeground(modal: false)))
        }
        .background(Color(.listBackground))
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
        .onAppear {
            viewModel.onViewAppear()
        }
        .alert(isPresented: $viewModel.shouldShowErrorAlert) {
            Alert(title: Text(viewModel.errorMessage),
                  dismissButton: .default(Text(Localization.gotIt)))
        }
        .alert(isPresented: $viewModel.shouldShowSuccessAlert) {
            Alert(title: Text(Localization.supportRequestSent),
                  dismissButton: .default(Text(Localization.gotIt), action: viewModel.dismissView))
        }
        .alert(Localization.IdentityInput.title, isPresented: $viewModel.shouldShowIdentityInput) {
            TextField(Localization.IdentityInput.email, text: $viewModel.contactEmailAddress)
            TextField(Localization.IdentityInput.name, text: $viewModel.contactName)
            Button(Localization.IdentityInput.cancel, action: viewModel.dismissView)
            Button(Localization.IdentityInput.ok, action: {
                Task {
                    await viewModel.submitIdentityInfo()
                }
            })
            .disabled(viewModel.identitySubmitButtonDisabled)
        }
    }
}

// MARK: Constants
private extension SupportForm {
    enum Localization {
        static let title = NSLocalizedString("Contact Support", comment: "Title of the view for contacting support.")
        static let iNeedHelp = NSLocalizedString("I need help with", comment: "Text on the support form to refer to what area the user has problem with.")
        static let letsGetItSorted = NSLocalizedString("Let’s get this sorted", comment: "Title to let the user know what do we want on the support screen.")
        static let tellUsInfo = NSLocalizedString(["Let us know your site address (URL) and tell us as much as you can about the problem,",
                                                  " and we will be in touch soon."].joined(),
                                                  comment: "Message info on the support screen.")
        static let subject = NSLocalizedString("Subject", comment: "Subject title on the support form")
        static let message = NSLocalizedString("Message", comment: "Message on the support form")
        static let submitRequest = NSLocalizedString("Submit Support Request", comment: "Button title to submit a support request.")

        static let requestSent = NSLocalizedString(
            "supportForm.supportRequestSent",
            value: "Request Sent!",
            comment: "Title for the alert after the support request is created."
        )
        static let supportRequestSent = NSLocalizedString(
            "supportForm.supportRequestSentMessage",
            value: "Your support request has landed safely in our inbox. We will reply via email as quickly as we can.",
            comment: "Message for the alert after the support request is created."
        )
        static let gotIt = NSLocalizedString(
            "supportForm.gotIt",
            value: "Got It",
            comment: "Button to dismiss the alert when a support request."
        )
        enum IdentityInput {
            static let title = NSLocalizedString(
                "supportForm.identityInput.title",
                value: "Please enter your email address and user name",
                comment: "Title of the input alert for identity info to be used in the support form"
            )
            static let email = NSLocalizedString(
                "supportForm.identityInput.email",
                value: "Email",
                comment: "Placeholder of the email field on the input alert for identity info to be used in the support form"
            )
            static let name = NSLocalizedString(
                "supportForm.identityInput.name",
                value: "Name",
                comment: "Placeholder of the name field on the input alert for identity info to be used in the support form"
            )
            static let cancel = NSLocalizedString(
                "supportForm.identityInput.cancel",
                value: "Cancel",
                comment: "Button to dismiss the input alert for identity info to be used in the support form"
            )
            static let ok = NSLocalizedString(
                "supportForm.identityInput.ok",
                value: "OK",
                comment: "Button to submit details on the input alert for identity info to be used in the support form"
            )
        }
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let radioButtonSpacing: CGFloat = 12
        static let radioButtonBorderWidth: CGFloat = 2
        static let radioButtonSize: CGFloat = 20
        static let subSectionsSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let subjectInsets = EdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5)
        static let minimuEditorSize: CGFloat = 300
    }
}

// MARK: Previews
struct SupportFormProvider: PreviewProvider {

    struct MockDataSource: SupportFormMetaDataSource {
        let formID: Int64 = 0
        let tags: [String] = []
        let customFields: [Int64: String] = [:]
    }

    static var previews: some View {
        NavigationView {
            SupportForm(viewModel: .init(areas: [
                .init(title: "Mobile Apps", datasource: MockDataSource()),
                .init(title: "Card Reader / In Person Payments", datasource: MockDataSource()),
                .init(title: "WooCommerce Payments", datasource: MockDataSource()),
                .init(title: "WooCommerce Plugins", datasource: MockDataSource()),
                .init(title: "Other Plugins", datasource: MockDataSource()),
            ]))
        }
    }
}

struct HostedSupportForm: UIViewControllerRepresentable {
    typealias UIViewControllerType = SupportFormHostingController

    let viewModel: SupportFormViewModel

    func makeUIViewController(context: Context) -> SupportFormHostingController {
        SupportFormHostingController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: SupportFormHostingController, context: Context) { }
}
