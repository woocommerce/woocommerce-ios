import UIKit
import Gridicons

class OrderNoteViewModel {
    let iconImage: UIImage
    let iconColor: UIColor
    private let formattedDate: Date?
    private let jsonDate: String
    let statusText: String
    let contents: String

    init(with orderNote: OrderNote) {
        iconImage = Gridicon.iconOfType(.aside)
        if orderNote.isCustomerNote {
            iconColor = StyleManager.statusPrimaryBoldColor
            statusText = NSLocalizedString("Note to customer", comment: "Labels an order note to let user know it's visible to the customer")
        } else {
            iconColor = StyleManager.wooGreyMid
            statusText = NSLocalizedString("Private note", comment: "Labels an order note to let the user know it's private and not seen by the customer")
        }

        jsonDate = orderNote.dateCreated
        let format = DateFormatter.Defaults.dateTimeFormatter
        formattedDate = format.date(from: orderNote.dateCreated)

        contents = orderNote.contents
    }

    var dateCreated: String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if let date = formattedDate {
            return formatter.string(from: date)
        }
        return jsonDate
    }
}
