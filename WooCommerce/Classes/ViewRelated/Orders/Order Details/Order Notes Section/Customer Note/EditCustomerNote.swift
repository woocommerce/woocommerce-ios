import Foundation
import Combine
import SwiftUI

/// Hosting controller that wraps an `EditCustomerNote` view.
///
final class EditCustomerNoteHostingController: UIHostingController<EditCustomerNote> {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    /// Presents an error notice in the current modal presentation context
    ///
    private lazy var modalNoticePresenter: NoticePresenter = {
        let presenter = DefaultNoticePresenter()
        presenter.presentingViewController = self
        return presenter
    }()

    /// Presents a success notice in the tab bar context after this `self` is dismissed.
    ///
    private let systemNoticePresenter: NoticePresenter

    init(viewModel: EditCustomerNoteViewModel, systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.systemNoticePresenter = systemNoticePresenter
        super.init(rootView: EditCustomerNote(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Observe the present notice intent and set it back after presented.
        viewModel.$presentNotice
            .compactMap { $0 }
            .sink { [weak self] notice in

                // To prevent keyboard to hide the notice
                self?.view.endEditing(true)

                switch notice {
                case .success:
                    self?.systemNoticePresenter.enqueue(notice: .init(title: EditCustomerNote.Localization.success, feedbackType: .success))
                case .error:
                    self?.modalNoticePresenter.enqueue(notice: .init(title: EditCustomerNote.Localization.error, feedbackType: .error))
                }

                // Nullify the presentation intent.
                viewModel.presentNotice = nil
            }
            .store(in: &subscriptions)

        // Set presentation delegate to track the user dismiss flow event
        presentationController?.delegate = self
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Intercepts to the dismiss drag gesture.
///
extension EditCustomerNoteHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        rootView.viewModel.userDidCancelFlow()
    }
}

/// Allows merchant to edit the customer provided note of an order.
///
struct EditCustomerNote: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// View Model for the view
    ///
    @ObservedObject private(set) var viewModel: EditCustomerNoteViewModel

    var body: some View {
        NavigationView {
            TextEditor(text: $viewModel.newNote)
                .padding()
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.cancel, action: {
                            viewModel.userDidCancelFlow()
                            dismiss()
                        })
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        navigationBarTrailingItem()
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    /// Decides if the navigation trailing item should be a done button or a loading indicator.
    ///
    @ViewBuilder private func navigationBarTrailingItem() -> some View {
        switch viewModel.navigationTrailingItem {
        case .done(let enabled):
            Button(Localization.done) {
                viewModel.updateNote(onFinish: { success in
                    if success {
                        dismiss()
                    }
                })
            }
            .disabled(!enabled)
        case .loading:
            ProgressView()
        }
    }
}

// MARK: Constants
private extension EditCustomerNote {
    enum Localization {
        static let title = NSLocalizedString("Edit Note", comment: "Title for the edit customer provided note screen")
        static let done = NSLocalizedString("Done", comment: "Text for the done button in the edit customer provided note screen")
        static let cancel = NSLocalizedString("Cancel", comment: "Text for the cancel button in the edit customer provided note screen")
        static let success = NSLocalizedString("Successfully updated", comment: "Notice text after updating the order successfully")
        static let error = NSLocalizedString("There was an error updating the order", comment: "Notice text after failing to update the order successfully")
    }
}
