import UIKit
import Yosemite
import Gridicons


// MARK: - SummaryTableViewCell
//
final class SummaryTableViewCell: UITableViewCell {

    /// Label: Title
    ///
    @IBOutlet private weak var titleLabel: UILabel!

    /// Label: Creation / Update Date
    ///
    @IBOutlet private weak var createdLabel: UILabel!

    /// Label: Payment Status
    ///
    @IBOutlet private weak var paymentStatusLabel: PaddedLabel!

    /// Button: Update Order Status
    ///
    @IBOutlet private var updateStatusButton: UIButton!

    /// Title
    ///
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    /// Date
    ///
    var dateCreated: String? {
        get {
            return createdLabel.text
        }
        set {
            createdLabel.text = newValue
        }
    }

    /// Closure to be executed whenever the pencil button is pressed.
    ///
    var onPencilTouchUp: (() -> Void)?

    /// Displays the specified OrderStatus, and applies the right Label Style
    ///
    func display(orderStatus: OrderStatus) {
        paymentStatusLabel.text = orderStatus.name
        paymentStatusLabel.applyStyle(for: orderStatus.status)
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        configureIcon()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        preserveLabelColors {
            super.setSelected(selected, animated: animated)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        preserveLabelColors {
            super.setHighlighted(highlighted, animated: animated)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        paymentStatusLabel.layer.borderColor = UIColor.clear.cgColor
    }
}


// MARK: - Private
//
private extension SummaryTableViewCell {

    /// Preserves the current Payment BG Color
    ///
    func preserveLabelColors(action: () -> Void) {
        let paymentColor = paymentStatusLabel.backgroundColor
        let borderColor = paymentStatusLabel.layer.borderColor

        action()

        paymentStatusLabel.backgroundColor = paymentColor
        paymentStatusLabel.layer.borderColor = borderColor
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyHeadlineStyle()
        createdLabel.applyFootnoteStyle()
        paymentStatusLabel.applyPaddedLabelDefaultStyles()
    }

    func configureIcon() {
        let pencilIcon = Gridicon.iconOfType(.pencil)
            .imageWithTintColor(tintColor)?
            .imageFlippedForRightToLeftLayoutDirection()
        updateStatusButton.setImage(pencilIcon, for: .normal)

        updateStatusButton.addTarget(self, action: #selector(editWasTapped), for: .touchUpInside)
    }

    @objc func editWasTapped() {
        onPencilTouchUp?()
    }
}
