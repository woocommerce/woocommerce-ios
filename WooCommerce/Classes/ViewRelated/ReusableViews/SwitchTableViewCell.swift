import UIKit


/// UITableViewCell (Subtitle Style) with a UISwitch on its right hand side.
///
class SwitchTableViewCell: UITableViewCell {

    /// Toggle Switch
    ///
    private let toggleSwitch = UISwitch()

    /// Closure to be executed whenever the Switch is flipped
    ///
    var onChange: ((Bool) -> Void)?

    /// Text: Title
    ///
    var title: String? {
        get {
            return textLabel?.text
        }
        set {
            textLabel?.text = newValue
        }
    }

    /// Text: Subtitle
    ///
    var subtitle: String? {
        get {
            return detailTextLabel?.text
        }
        set {
            detailTextLabel?.text = newValue
        }
    }

    /// Boolean indicating if the Switch is On or Off.
    ///
    var isOn: Bool {
        get {
            return toggleSwitch.isOn
        }
        set {
            toggleSwitch.isOn = newValue
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        setupTextLabels()
        setupSwitch()
        setupGestureRecognizers()
    }

    @IBAction func toggleSwitchWasPressed() {
        onChange?(toggleSwitch.isOn)
    }
}


// MARK: - Private Methods
//
private extension SwitchTableViewCell {

    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func setupTextLabels() {
        textLabel?.text = String()
        textLabel?.applyBodyStyle()

        detailTextLabel?.text = String()
        detailTextLabel?.applyFootnoteStyle()
        detailTextLabel?.numberOfLines = 0
    }

    func setupSwitch() {
        toggleSwitch.onTintColor = .primary
        toggleSwitch.addTarget(self, action: #selector(toggleSwitchWasPressed), for: .touchUpInside)
        accessoryView = toggleSwitch
    }

    func setupGestureRecognizers() {
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on { [weak self] gesture in
            self?.contentViewWasPressed()
        }

        addGestureRecognizer(gestureRecognizer)
    }

    func contentViewWasPressed() {
        let newValue = !toggleSwitch.isOn
        toggleSwitch.setOn(newValue, animated: true)
        onChange?(newValue)
    }
}
