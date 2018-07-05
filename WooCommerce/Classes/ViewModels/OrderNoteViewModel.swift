import UIKit
import Gridicons
import Yosemite

class OrderNoteViewModel {

    let iconImage: UIImage
    let iconColor: UIColor
    let statusText: String
    let contents: String
    let dateCreated: Date

    init(with orderNote: OrderNote) {
        iconImage = Gridicon.iconOfType(.aside)

        if orderNote.isCustomerNote {
            iconColor = StyleManager.statusPrimaryBoldColor
            statusText = NSLocalizedString("Note to customer", comment: "Labels an order note to let user know it's visible to the customer")
        } else {
            iconColor = StyleManager.wooGreyMid
            statusText = NSLocalizedString("Private note", comment: "Labels an order note to let the user know it's private and not seen by the customer")
        }

        dateCreated = orderNote.dateCreated
        contents = orderNote.contents
    }

    var formattedDateCreated: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(from: dateCreated)
    }
}
