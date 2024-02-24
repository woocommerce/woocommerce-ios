import UIKit


/// Represents a regular UITableView Cell: [Image | Text |  Disclosure]
///
class LeftImageTableViewCell: UITableViewCell {

    /// Left Image
    ///
    var leftImage: UIImage? {
        get {
            return imageView?.image
        }
        set {
            imageView?.image = newValue
        }
    }

    /// Label's Text
    ///
    var labelText: String? {
        get {
            return textLabel?.text
        }
        set {
            textLabel?.text = newValue
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        imageView?.tintColor = .primary
        textLabel?.applyBodyStyle()
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }

    private func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }
}

// MARK: - Public Methods
//
extension LeftImageTableViewCell {
    func configure(image: UIImage, text: String) {
        imageView?.image = image
        textLabel?.text = text
    }

    // Custom configure, with optional image and changeable text color
    func configure(image: UIImage?, text: String, textColor: UIColor) {
        imageView?.image = image
        textLabel?.text = text
        textLabel?.textColor = textColor
    }
}
