import Foundation
import SwiftUI
import Combine

/// Hosting controller that wraps a `ReviewDetailsReply` view.
///
final class ReviewReplyHostingController: UIHostingController<ReviewReply>, UIAdaptivePresentationControllerDelegate {

    private let viewModel: ReviewReplyViewModel

    /// Presents notices in the tab bar context.
    ///
    private let systemNoticePresenter: NoticePresenter

    /// Presents notices in the current modal presentation context.
    ///
    private lazy var modalNoticePresenter: NoticePresenter = {
        let presenter = DefaultNoticePresenter()
        presenter.presentingViewController = self
        return presenter
    }()

    /// Emits the intent to present a `ReviewReplyNotice`
    ///
    private lazy var presentNoticePublisher = {
        viewModel.presentNoticeSubject.eraseToAnyPublisher()
    }()

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: ReviewReplyViewModel,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.viewModel = viewModel
        self.systemNoticePresenter = noticePresenter
        super.init(rootView: ReviewReply(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Observe the present notice intent.
        presentNoticePublisher
            .compactMap { $0 }
            .sink { [weak self] notice in
                switch notice {
                case .success:
                    self?.systemNoticePresenter.enqueue(notice: Notice(title: Localization.success, feedbackType: .success))
                case .error:
                    // Include a notice identifier so the the error can be presented as a system notification even if the app is closed.
                    let noticeIdentifier = UUID().uuidString
                    let notice = Notice(title: Localization.error,
                                        feedbackType: .error,
                                        notificationInfo: NoticeNotificationInfo(identifier: noticeIdentifier),
                                        actionTitle: Localization.retry) { [weak self] in
                        self?.viewModel.sendReply(onCompletion: { [weak self] success in
                            if success {
                                self?.dismiss(animated: true, completion: nil)
                            }
                        })
                    }

                    self?.modalNoticePresenter.enqueue(notice: notice)
                }
            }
            .store(in: &subscriptions)

        // Set presentation delegate to track the user dismiss flow event
        presentationController?.delegate = self
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Allows merchant to reply to a product review.
///
struct ReviewReply: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// View Model for the view
    ///
    @ObservedObject private(set) var viewModel: ReviewReplyViewModel

    var body: some View {
        NavigationView {
            TextEditor(text: $viewModel.newReply)
                .focused()
                .padding()
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.cancel, action: {
                            dismiss()
                        })
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        navigationBarTrailingItem()
                    }
                }
        }
        .wooNavigationBarStyle()
        .navigationViewStyle(.stack)
    }

    /// Decides if the navigation trailing item should be a send button or a loading indicator.
    ///
    @ViewBuilder private func navigationBarTrailingItem() -> some View {
        switch viewModel.navigationTrailingItem {
        case .send(let enabled):
            Button(Localization.send) {
                viewModel.sendReply { success in
                    if success {
                        dismiss()
                    }
                }
            }
            .disabled(!enabled)
        case .loading:
            ProgressView()
        }
    }
}

enum ReviewReplyNotice: Equatable {
    case success
    case error
}

// MARK: Constants
private enum Localization {
    static let title = NSLocalizedString("Reply to Product Review", comment: "Title for the product review reply screen")
    static let send = NSLocalizedString("Send", comment: "Text for the send button in the product review reply screen")
    static let cancel = NSLocalizedString("Cancel", comment: "Text for the cancel button in the product review reply screen")

    // Notice strings
    static let success = NSLocalizedString("Reply sent!", comment: "Notice text after sending a reply to a product review successfully")
    static let error = NSLocalizedString("There was an error sending the reply", comment: "Notice text after failing to send a reply to a product review")
    static let retry = NSLocalizedString("Retry", comment: "Retry Action")
}
