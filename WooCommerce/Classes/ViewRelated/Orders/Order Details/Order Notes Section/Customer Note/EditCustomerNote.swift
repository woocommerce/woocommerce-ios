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
        Text("Empty")
    }
}

// MARK: Previews
struct EditCustomerNote_Previews: PreviewProvider {
    static var previews: some View {
        EditCustomerNote()
            .environment(\.colorScheme, .light)
    }
}
