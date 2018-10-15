import UIKit

class SwitchTableViewCell: UITableViewCell {

    // MARK: - Properties
    //
    @IBOutlet public var topLabel: UILabel!
    @IBOutlet public var bottomLabel: UILabel!
    @IBOutlet public var toggleSwitch: UISwitch!

    var onToggleSwitchTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        topLabel.applyBodyStyle()
        bottomLabel.applyFootnoteStyle()
        toggleSwitch.onTintColor = StyleManager.wooCommerceBrandColor
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
