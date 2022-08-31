import UIKit


/// Represents a regular UITableView Cell with subtitle: [Image | Text + Subtitle |  Disclosure]
///
class LeftImageTitleSubtitleToggleTableViewCell: UITableViewCell {


    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!

    /// Left Image
    ///
    var leftImage: UIImage? {
        get {
            return leftImageView?.image
        }
        set {
            leftImageView?.image = newValue
        }
    }

    /// Label's Text
    ///
    var labelText: String? {
        get {
            return titleLabel?.text
        }
        set {
            titleLabel?.text = newValue
        }
    }

    /// Subtitle's text
    ///
    var subtitleLabelText: String? {
        get {
            return subtitleLabel?.text
        }
        set {
            subtitleLabel?.text = newValue
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        leftImageView?.tintColor = .primary
        titleLabel?.applyBodyStyle()
        subtitleLabel?.applyFootnoteStyle()
        toggleSwitch?.onTintColor = .primary
    }

    private func configureBackground() {
        applyDefaultBackgroundStyle()
    }
}

// MARK: - Public Methods
//
extension LeftImageTitleSubtitleToggleTableViewCell {
    func configure(image: UIImage, text: String, subtitle: String, switchState: Bool) {
        configure(image: image, text: text, subtitle: subtitle, attributedSubtitle: nil, switchState: switchState)
    }

    func configure(image: UIImage, text: String, subtitle: NSAttributedString, switchState: Bool) {
        configure(image: image, text: text, subtitle: nil, attributedSubtitle: subtitle, switchState: switchState)
    }

    private func configure(image: UIImage,
                           text: String,
                           subtitle: String?,
                           attributedSubtitle: NSAttributedString?,
                           switchState: Bool) {
        leftImageView?.image = image
        titleLabel?.text = text
        subtitleLabel?.text = subtitle
        subtitleLabel.attributedText = attributedSubtitle
        toggleSwitch.isOn = switchState
    }
}
