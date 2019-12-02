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

    private func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }
}

// MARK: - Public Methods
//
extension LeftImageTableViewCell {
    func configure(image: UIImage, text: String) {
        imageView?.image = image
        textLabel?.text = text
    }
}
