import UIKit

class SwitchTableViewCell: UITableViewCell {

    // MARK: - Properties
    //
    @IBOutlet private var topLabel: UILabel!
    @IBOutlet private var bottomLabel: UILabel!
    @IBOutlet private var toggleSwitch: UISwitch!

    var onToggleSwitchTouchUp: (() -> Void)?

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

    override func awakeFromNib() {
        super.awakeFromNib()
        topLabel.applyBodyStyle()
        bottomLabel.applyFootnoteStyle()
        setupGestureRecognizers()
    }

    @IBAction func toggleSwitchWasPressed() {
        onToggleSwitchTouchUp?()
    }
}


// MARK: - Private Methods
//
private extension SwitchTableViewCell {

    func setupGestureRecognizers() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on { [weak self] gesture in
            self?.contentViewWasPressed()
        }

        addGestureRecognizer(gestureRecognizer)
    }

    func contentViewWasPressed() {
        toggleSwitch.isOn = !toggleSwitch.isOn
        onToggleSwitchTouchUp?()
    }
}
