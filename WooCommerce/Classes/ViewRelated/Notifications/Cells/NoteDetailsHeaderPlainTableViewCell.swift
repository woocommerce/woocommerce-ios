import Foundation
import UIKit


// MARK: - NoteDetailsHeaderPlainTableViewCell
//
final class NoteDetailsHeaderPlainTableViewCell: UITableViewCell {

    /// Accessory's Image View
    ///
    private let accessoryImageView = UIImageView(frame: CGRect(origin: .zero, size: Settings.accessorySize))

    /// Image to be rendered on the left side of the cell
    ///
    var leftImage: UIImage? {
        get {
            return imageView?.image
        }
        set {
            imageView?.image = newValue
        }
    }

    /// Image to be rendered on the right side of the cell
    ///
    var rightImage: UIImage? {
        get {
            return accessoryImageView.image
        }
        set {
            accessoryImageView.image = newValue
        }
    }

    /// Text to be rendered
    ///
    var plainText: String? {
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
        configureImages()
        configureLabels()
    }
}


// MARK: - Private Methods
//
private extension NoteDetailsHeaderPlainTableViewCell {

    /// Setup: Cell background
    ///
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    /// Setup: Images
    ///
    func configureImages() {
        imageView?.tintColor = .textSubtle
        accessoryImageView.tintColor = .primary
        accessoryView = accessoryImageView
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        textLabel?.font = UIFont.body
        textLabel?.textColor = .text
    }
}


// MARK: - Settings
//
private enum Settings {
    static let accessorySize = CGSize(width: 25, height: 25)
}
