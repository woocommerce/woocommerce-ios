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

    override func viewDidLoad() {
        super.viewDidLoad()
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
        viewModel.onCompletion = { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.informSuccessAndPopBack()
            case .failure(let error):
                self.logAndInformErrorCreatingRequest(error)
            }
        }
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SupportFormHostingController {
    /// Shows an alert informing the support creation success and after confirmation dismisses the view.
    ///
    func informSuccessAndPopBack() {
        let alertController = UIAlertController(title: Localization.requestSent,
                                                message: Localization.requestSentMessage,
                                                preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(Localization.gotIt) { _ in
            self.dismissView()
        }
        present(alertController, animated: true)
    }

    /// Logs and informs the user that a support request could not be created
    ///
    func logAndInformErrorCreatingRequest(_ error: Error) {
        let notice = Notice(title: Localization.requestSentError, feedbackType: .error)
        noticePresenter.enqueue(notice: notice)

        DDLogError("⛔️ Could not create Support Request. Error: \(error.localizedDescription)")
    }

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
        static let requestSent = NSLocalizedString("Request Sent!", comment: "Title for the alert after the support request is created.")
        static let requestSentMessage = NSLocalizedString("Your support request has landed safely in our inbox. We will reply via email as quickly as we can.",
                                                          comment: "Message for the alert after the support request is created.")
        static let gotIt = NSLocalizedString("Got It!", comment: "Confirmation button for the alert after the support request is created.")

        static let badIdentityError = NSLocalizedString("Sorry, we cannot create support requests right now, please try again later.",
                                                        comment: "Error message when the app can't create a zendesk identity.")
        static let requestSentError = NSLocalizedString("Sorry, we could not create your support request, please try again later.",
                                                        comment: "Error message when the app can't create a support request.")
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
            viewModel.trackSupportFormViewed()
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
