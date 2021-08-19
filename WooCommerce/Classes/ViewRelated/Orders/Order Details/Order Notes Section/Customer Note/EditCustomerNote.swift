import Foundation
import SwiftUI

/// Hosting controller that wraps an `EditCustomerNote` view.
///
final class EditCustomerNoteHostingController: UIHostingController<EditCustomerNote> {
    init() {
        super.init(rootView: EditCustomerNote())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Allows merchant to edit the customer provided note of an order.
///
struct EditCustomerNote: View {
    var body: some View {
        NavigationView {
            Text("Empty")
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button(Localization.cancel) {
                        print("Cancel tapped")
                    },
                    trailing: Button(Localization.done) {
                        print("Done tapped")
                    }
                )
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
