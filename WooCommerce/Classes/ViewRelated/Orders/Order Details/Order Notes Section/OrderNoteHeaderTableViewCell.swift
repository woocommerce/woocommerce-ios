import UIKit


// MARK: - OrderNoteHeaderTableViewCell
//
final class OrderNoteHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }

    /// Date of Creation: To be displayed in the cell
    ///
    var dateCreated: String? {
        get {
            return dateLabel.text
        }
        set {
            dateLabel.text = newValue
        }
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

}

// MARK: - Private Methods
//
private extension OrderNoteHeaderTableViewCell {

    /// Setup: Cell background
    ///
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        dateLabel.applyHeadlineStyle()
    }
}
