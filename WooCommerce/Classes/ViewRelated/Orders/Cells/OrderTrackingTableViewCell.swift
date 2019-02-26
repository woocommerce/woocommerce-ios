import UIKit


/// Displays the list of Products associated to an Order.
///
final class OrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet public var verticalStackView: UIStackView!
    
    @IBOutlet weak var trackButton: UIButton!
    @IBOutlet public var actionContainerView: UIView!

    var onTrackTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        trackButton.applySecondaryButtonStyle()
        verticalStackView.setCustomSpacing(Constants.spacing, after: trackButton)
    }
}

extension OrderTrackingTableViewCell {
    @IBAction func trackWasPressed() {
        onTrackTouchUp?()
    }

    struct Constants {
        static let spacing = CGFloat(8.0)
    }
}
