import UIKit


/// Represents a regular UITableView Cell with subtitle: [Image | Text + Subtitle |  Disclosure]
///
class LeftImageTitleSubtitleTableViewCell: UITableViewCell {

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

    /// Subtitle's text
    ///
    var subtitleLabelText: String? {
        get {
            return detailTextLabel?.text
        }
        set {
            detailTextLabel?.text = newValue
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        imageView?.tintColor = .primary
        textLabel?.applyBodyStyle()
        detailTextLabel?.applyFootnoteStyle()
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
extension LeftImageTitleSubtitleTableViewCell {
    func configure(image: UIImage, text: String, subtitle: String) {
        imageView?.image = image
        textLabel?.text = text
        detailTextLabel?.text = subtitle
    }
}
