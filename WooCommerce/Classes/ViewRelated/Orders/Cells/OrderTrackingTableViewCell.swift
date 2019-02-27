import UIKit


/// Displays the list of Products associated to an Order.
///
final class OrderTrackingTableViewCell: UITableViewCell {
    @IBOutlet weak var topLine: UILabel!
    @IBOutlet weak var bottomLine: UILabel!

    @IBOutlet weak var actionButton: UIButton!

    var onActionTouchUp: (() -> Void)?

    var topText: String? {
        get {
            return topLine.text
        }
        set {
            topLine.text = newValue
        }
    }

    var bottomText: String? {
        get {
            return bottomLine.text
        }
        set {
            bottomLine.text = newValue
        }
    }

    var actionButtonNormalText: String? {
        get {
            return actionButton.title(for: .normal)
        }
        set {
            actionButton.setTitle(newValue, for: .normal)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureTopLine()
        configureBottomLine()
        configureActionButton()
    }

    private func configureTopLine() {
        topLine.applyHeadlineStyle()
    }

    private func configureBottomLine() {
        bottomLine.applySubheadlineStyle()
    }

    private func configureActionButton() {
        actionButton.applySecondaryButtonStyle()
    }
}

extension OrderTrackingTableViewCell {
    @IBAction func actionButtonPressed(_ sender: Any) {
        onActionTouchUp?()
    }
}
