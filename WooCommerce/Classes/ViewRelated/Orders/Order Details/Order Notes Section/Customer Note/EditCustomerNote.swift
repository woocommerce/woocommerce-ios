import Foundation
import Combine
import SwiftUI

/// Hosting controller that wraps an `EditCustomerNote` view.
///
final class EditCustomerNoteHostingController<ViewModel: EditCustomerNoteViewModelProtocol>: UIHostingController<EditCustomerNote<ViewModel>>,
                                                                                             UIAdaptivePresentationControllerDelegate {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: ViewModel) {
        super.init(rootView: EditCustomerNote(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Set presentation delegate to track the user dismiss flow event
        presentationController?.delegate = self
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Intercepts to the dismiss drag gesture.
    ///
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        rootView.viewModel.userDidCancelFlow()
    }
}

/// Allows merchant to edit the customer provided note of an order.
///
struct EditCustomerNote<ViewModel: EditCustomerNoteViewModelProtocol>: View {

    /// Set this closure with UIKit dismiss code. Needed because we need access to the UIHostingController `dismiss` method.
    ///
    var dismiss: (() -> Void) = {}

    /// View Model for the view
    ///
    @ObservedObject private(set) var viewModel: ViewModel

    var body: some View {
        NavigationView {
            TextEditor(text: $viewModel.newNote)
                .focused()
                .padding()
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationViewStyle(StackNavigationViewStyle())
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
        .wooNavigationBarStyle()
    }

    /// Decides if the navigation trailing item should be a done button or a loading indicator.
    ///
    @ViewBuilder private func navigationBarTrailingItem() -> some View {
        switch viewModel.navigationTrailingItem {
        case .done(let enabled):
            Button(Localization.done) {
                if let didSelectDone = viewModel.didSelectDone {
                    didSelectDone(viewModel.newNote)
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
    static let title = NSLocalizedString("Edit Note", comment: "Title for the edit customer provided note screen")
    static let done = NSLocalizedString("Done", comment: "Text for the done button in the edit customer provided note screen")
    static let cancel = NSLocalizedString("Cancel", comment: "Text for the cancel button in the edit customer provided note screen")
}
