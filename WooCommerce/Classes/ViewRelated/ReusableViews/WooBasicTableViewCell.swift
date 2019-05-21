import UIKit


// MARK: - WooBasicTableViewCell

/// A UITableViewCell with bonus purple Woo styling.
///
/// For reasons I cannot figure out, a `BasicTableViewCell` has
/// a different leading margin ("left margin") measurement than
/// a custom one. Custom cells follow the superview margin. Custom
/// cells sets a 30 point leading margin on an iPhone XS Max.
/// But a BasicTableViewCell sets the leading margin to 20 points.
/// So here we are, building a basic table view cell as a custom cell,
/// so that the margins match. --- ¯\_(ツ)_/¯ 21.05.2019 tc
///
class WooBasicTableViewCell: UITableViewCell {

    @IBOutlet weak var bodyLabel: UILabel!

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
        bodyLabel?.applyBodyStyle()
        bodyLabel?.textColor = StyleManager.wooCommerceBrandColor
    }

    /// Add the accessoryView image, if any
    ///
    func configureAccessoryView() {
        let accessoryImageView = UIImageView(image: accessoryImage)
        accessoryImageView.tintColor = StyleManager.buttonPrimaryColor
        accessoryView = accessoryImageView
    }
}
