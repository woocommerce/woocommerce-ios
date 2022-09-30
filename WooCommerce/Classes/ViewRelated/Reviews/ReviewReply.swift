import Foundation
import SwiftUI

/// Hosting controller that wraps a `ReviewDetailsReply` view.
///
final class ReviewReplyHostingController: UIHostingController<ReviewReply>, UIAdaptivePresentationControllerDelegate {

    private let viewModel: ReviewReplyViewModel

    init(viewModel: ReviewReplyViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ReviewReply(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // This notice presenter is needed to display an error notice without closing the modal if the network request fails.
        let errorNoticePresenter = DefaultNoticePresenter()
        errorNoticePresenter.presentingViewController = self
        viewModel.modalNoticePresenter = errorNoticePresenter

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

// MARK: Constants
private enum Localization {
    static let title = NSLocalizedString("Reply to Product Review", comment: "Title for the product review reply screen")
    static let send = NSLocalizedString("Send", comment: "Text for the send button in the product review reply screen")
    static let cancel = NSLocalizedString("Cancel", comment: "Text for the cancel button in the product review reply screen")
}
