import UIKit
import Gridicons


// MARK: - OrderNoteTableViewCell
//
class OrderNoteTableViewCell: UITableViewCell {

    /// Top Left Icon
    ///
    @IBOutlet private var iconButton: UIButton!

    /// Top Right Label
    ///
    @IBOutlet private var dateLabel: UILabel!

    /// Secondary Top Label
    ///
    @IBOutlet private var statusLabel: UILabel!

    /// Bottom Label
    ///
    @IBOutlet private var noteLabel: UILabel!


    // MARK: - View Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        configureLabels()
        configureIconButton()
    }


    /// Date of Creation: To be displayed at the top of the cell
    ///
    var dateCreated: String? {
        get {
            return dateLabel.text
        }
        set {
            dateLabel.text = newValue
        }
    }

    /// Note's Payload
    ///
    var contents: String? {
        get {
            return noteLabel.text
        }
        set {
            noteLabel.text = newValue
        }
    }

    /// Indicates if the note is visible to the Customer (or it's set to private!)
    ///
    var isCustomerNote: Bool = false {
        didSet {
            privacyWasUpdated()
        }
    }
}


// MARK: - Private Methods
//
private extension OrderNoteTableViewCell {

    /// Updates the Status Label + Icon's Color
    ///
    func privacyWasUpdated() {
        if isCustomerNote {
            iconButton.backgroundColor = StyleManager.statusPrimaryBoldColor
            statusLabel.text = NSLocalizedString("Note to customer", comment: "Labels an order note to let user know it's visible to the customer")
        } else {
            iconButton.backgroundColor = StyleManager.wooGreyMid
            statusLabel.text = NSLocalizedString("Private note", comment: "Labels an order note to let the user know it's private and not seen by the customer")
        }
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        dateLabel.applyBodyStyle()
        noteLabel.applyBodyStyle()
        statusLabel.applyBodyStyle()
        statusLabel.textColor = StyleManager.wooGreyMid
    }

    /// Setup: Icon Button
    ///
    func configureIconButton() {
        let image = Gridicon.iconOfType(.aside)
        iconButton.setImage(image, for: .normal)
        iconButton.layer.cornerRadius = iconButton.frame.width / 2
        iconButton.tintColor = .white
    }
}
