import UIKit

class ToggleEmailCustomerTableViewCell: UITableViewCell {

    // MARK: - Properties
    //
    @IBOutlet var topLabel: UILabel!
    @IBOutlet var bottomLabel: UILabel!
    @IBOutlet var toggleSwitch: UISwitch!

    @IBAction func toggleSwitchWasPressed() {
        onToggleSwitchTouchUp?()
    }

    var onToggleSwitchTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        topLabel.applyBodyStyle()
        bottomLabel.applyFootnoteStyle()

        topLabel.text = NSLocalizedString("Email note to customer", comment: "Label for yes/no switch - emailing the note to customer.")
        bottomLabel.text = NSLocalizedString("If disabled will add the note as private.", comment: "Detail label for yes/no switch.")
    }
}
