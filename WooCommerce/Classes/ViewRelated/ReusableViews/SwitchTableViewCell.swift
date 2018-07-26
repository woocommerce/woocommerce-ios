import UIKit

class SwitchTableViewCell: UITableViewCell {

    // MARK: - Properties
    //
    @IBOutlet private var topLabel: UILabel!
    @IBOutlet private var bottomLabel: UILabel!
    @IBOutlet private var toggleSwitch: UISwitch!

    @IBAction func toggleSwitchWasPressed() {
        onToggleSwitchTouchUp?()
    }

    var topText: String? {
        get {
            return topLabel.text
        }
        set {
            topLabel.text = newValue
        }
    }

    var bottomText: String? {
        get {
            return bottomLabel.text
        }
        set {
            bottomLabel.text = newValue
        }
    }

    var onToggleSwitchTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        topLabel.applyBodyStyle()
        bottomLabel.applyFootnoteStyle()
    }
}
