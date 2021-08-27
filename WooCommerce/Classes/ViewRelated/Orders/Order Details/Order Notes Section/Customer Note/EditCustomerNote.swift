import Foundation
import Combine
import SwiftUI

/// Hosting controller that wraps an `EditCustomerNote` view.
///
final class EditCustomerNoteHostingController: UIHostingController<EditCustomerNote> {

    /// References to keep the Combine subscriptions alive within the lifecycle of the object.
    ///
    private var subscriptions: Set<AnyCancellable> = []

    init(viewModel: EditCustomerNoteViewModel) {
        super.init(rootView: EditCustomerNote(viewModel: viewModel))

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }

        // Observe the present notice request and set it back after presented
        viewModel.$presentNotice
            .compactMap { $0 }
            .removeDuplicates()
            .sink { notice in
                switch notice {
                case .success:
                    print("Show success")
                case .error:
                    print("Show Error")
                }
            }
            .store(in: &subscriptions)
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                .navigationBarItems(trailing: navigationBarTrailingItem()) // The only way I've found to make buttons bold is to set them here.
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(Localization.cancel, action: dismiss)
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
                viewModel.updateNote(onFinish: dismiss)
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
    }
}
