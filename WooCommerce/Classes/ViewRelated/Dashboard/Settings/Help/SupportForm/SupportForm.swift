import Foundation
import SwiftUI

/// Hosting Controller for the Support Form.
///
final class SupportFormHostingController: UIHostingController<SupportForm> {

    init(viewModel: SupportFormViewModel) {
        super.init(rootView: SupportForm(viewModel: viewModel))
        handleSupportRequestCompletion(viewModel: viewModel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createZendeskIdentity()
    }

    /// Creates the Zendesk Identity if needed.
    /// If it fails, it pops back the view and informs the user.
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
    /// Shows an alert informing the support creation success and after confirmation pops the view back.
    ///
    func informSuccessAndPopBack() {
        let alertController = UIAlertController(title: Localization.requestSent,
                                                message: Localization.requestSentMessage,
                                                preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(Localization.gotIt) { _ in
            self.navigationController?.popViewController(animated: true)
        }
        present(alertController, animated: true)
    }

    /// Logs and informs the user that a support request could not be created
    ///
    func logAndInformErrorCreatingRequest(_ error: Error) {
        let notice = Notice(title: Localization.requestSentError, feedbackType: .error)
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        noticePresenter.enqueue(notice: notice)

        DDLogError("⛔️ Could not create Support Request. Error: \(error.localizedDescription)")
    }

    /// Informs user about identity error and pop back
    ///
    func logIdentityErrorAndPopBack() {
        let notice = Notice(title: Localization.badIdentityError, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)

        navigationController?.popViewController(animated: true)
        DDLogError("⛔️ Zendesk Identity could not be created.")
    }
}

private extension SupportFormHostingController {
    enum Localization {
        static let requestSent = NSLocalizedString("Request Sent!", comment: "Title for the alert after the support request is created.")
        static let requestSentMessage = NSLocalizedString("Your support request has landed safely in our inbox, we will reply shortly via email.",
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
        VStack(spacing: Layout.sectionSpacing) {

            HStack(spacing: -Layout.optionsSpacing) {
                Text(Localization.iNeedHelp)
                    .bold()
                Picker(Localization.iNeedHelp, selection: $viewModel.area) {
                    ForEach(viewModel.areas, id: \.self) { area in
                        Text(area.title).tag(area)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                Text(Localization.subject)
                    .bold()
                TextField("", text: $viewModel.subject)
                    .bodyStyle()
                    .padding(Layout.subjectPadding)
                    .border(Color(.separator))
                    .cornerRadius(Layout.cornerRadius)
            }

            VStack(alignment: .leading, spacing: Layout.subSectionsSpacing) {
                Text(Localization.whatToDo)
                    .bold()
                TextEditor(text: $viewModel.description)
                    .bodyStyle()
                    .border(Color(.separator))
                    .cornerRadius(Layout.cornerRadius)
            }

            Button {
                viewModel.submitSupportRequest()
            } label: {
                Text(Localization.submitRequest)
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.showLoadingIndicator))
            .disabled(viewModel.submitButtonDisabled)
        }
        .padding()
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .wooNavigationBarStyle()
    }
}

// MARK: Constants
private extension SupportForm {
    enum Localization {
        static let title = NSLocalizedString("Contact Support", comment: "Title of the view for contacting support.")
        static let iNeedHelp = NSLocalizedString("I need help with:", comment: "Text on the support form to refer to what area the user has problem with.")
        static let subject = NSLocalizedString("Subject", comment: "Subject title on the support form")
        static let whatToDo = NSLocalizedString("What are you trying to do?", comment: "Text on the support form to ask the user what are they trying to do.")
        static let submitRequest = NSLocalizedString("Submit Support Request", comment: "Button title to submit a support request.")
    }

    enum Layout {
        static let sectionSpacing: CGFloat = 16
        static let optionsSpacing: CGFloat = 8
        static let subSectionsSpacing: CGFloat = 2
        static let cornerRadius: CGFloat = 2
        static let subjectPadding: CGFloat = 5
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
                .init(title: "Mobile Aps", datasource: MockDataSource()),
                .init(title: "WooCommerce Payments", datasource: MockDataSource()),
                .init(title: "Other Plugins", datasource: MockDataSource()),
            ]))
        }
    }
}
