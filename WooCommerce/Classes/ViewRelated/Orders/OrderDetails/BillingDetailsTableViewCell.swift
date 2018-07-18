import UIKit
import WordPressUI


/// Displays Billing Details: Used for Email / Phone Number Rendering.
///
class BillingDetailsTableViewCell: UITableViewCell {

    /// AccessoryView's Image
    ///
    private let accessoryImageView: UIImageView = {
        let imageView = UIImageView(frame: Constants.accessoryFrame)
        imageView.tintColor = StyleManager.wooCommerceBrandColor
        return imageView
    }()

    /// Closure to be executed whenever the cell is pressed.
    ///
    var onTouchUp: (() -> Void)?


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()

        textLabel?.applyBodyStyle()
        textLabel?.adjustsFontSizeToFitWidth = true

        accessoryView = accessoryImageView

        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on { [weak self] gesture in
            self?.onTouchUp?()
        }

        contentView.gestureRecognizers = [gestureRecognizer]
    }

    func configure(text: String?, image: UIImage) {
        accessoryImageView.image = image
        textLabel?.text = text
    }
}


// MARK: - Private
//
private extension BillingDetailsTableViewCell {
    struct Constants {
        static let accessoryFrame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
}
