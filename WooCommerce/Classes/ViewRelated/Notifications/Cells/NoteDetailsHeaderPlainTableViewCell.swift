import Foundation
import UIKit


// MARK: - NoteDetailsHeaderPlainTableViewCell
//
class NoteDetailsHeaderPlainTableViewCell: UITableViewCell {

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

        imageView?.tintColor = StyleManager.wooGreyTextMin
        accessoryImageView.tintColor = StyleManager.wooCommerceBrandColor
        accessoryView = accessoryImageView
        textLabel?.font = UIFont.body
    }
}


// MARK: - Settings
//
private enum Settings {
    static let accessorySize = CGSize(width: 25, height: 25)
}
