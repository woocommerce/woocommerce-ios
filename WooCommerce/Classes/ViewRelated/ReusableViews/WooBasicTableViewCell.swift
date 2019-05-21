import UIKit


// MARK: - WooBasicTableViewCell

/// A subclassed BasicTableViewCell
/// with bonus purple Woo styling.
///
class WooBasicTableViewCell: BasicTableViewCell {

    public var accessoryImage: UIImage? {
        didSet {
            configureAccessoryView()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureSelectionStyle()
        configureLabel()
    }

    /// Set up the cell selection style
    ///
    func configureSelectionStyle() {
        selectionStyle = .default
    }

    /// Style the label(s)
    ///
    func configureLabel() {
        textLabel?.textColor = StyleManager.wooCommerceBrandColor
    }

    /// Add the accessoryView image, if any
    ///
    func configureAccessoryView() {
        let accessoryImageView = UIImageView(image: accessoryImage)
        accessoryImageView.tintColor = StyleManager.buttonPrimaryColor
        accessoryView = accessoryImageView
    }
}
