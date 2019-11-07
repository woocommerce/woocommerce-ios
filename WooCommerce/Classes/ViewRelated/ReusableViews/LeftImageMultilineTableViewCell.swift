import UIKit


/// Represents a UITableView Cell: [Image | Text ] which support multiline
///
class LeftImageMultilineTableViewCell: UITableViewCell {

    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var multilineLabel: UILabel!
    
    /// Left Image, anchored on top left
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
            return multilineLabel?.text
        }
        set {
            multilineLabel?.text = newValue
        }
    }

    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureImageView()
        configureTextLabel()
    }
    
}

// MARK: - Private Methods
//

private extension LeftImageMultilineTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureImageView() {
        leftImageView?.tintColor = StyleManager.wooCommerceBrandColor
    }
    
    func configureTextLabel() {
        multilineLabel?.applyBodyStyle()
        multilineLabel?.numberOfLines = 0
    }
}

// MARK: - Public Methods
//
extension LeftImageMultilineTableViewCell {
    func configure(image: UIImage, text: String) {
        imageView?.image = image
        textLabel?.text = text
    }
}
