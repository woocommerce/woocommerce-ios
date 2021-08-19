import Foundation
import SwiftUI

/// Hosting controller that wraps an `EditCustomerNote` view.
///
final class EditCustomerNoteHostingController: UIHostingController<EditCustomerNote> {
    init() {
        super.init(rootView: EditCustomerNote())

        // Needed because a `SwiftUI` cannot be dismissed when being presented by a UIHostingController
        rootView.dismiss = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
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

    // TODO: Replace with view model backed value
    @State private var textContent = "Tap and edit me"

    var body: some View {
        NavigationView {
            TextEditor(text: $textContent)
                .padding()
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button(Localization.done) { // I couldn't find a way to make the "Done" button bold using a toolbar :-(
                    // TODO: submit done action
                    print("Done tapped")
                })
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(Localization.cancel, action: dismiss)
                    }
                }
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

// MARK: Previews
struct EditCustomerNote_Previews: PreviewProvider {
    static var previews: some View {
        EditCustomerNote()
            .environment(\.colorScheme, .light)
    }
}
