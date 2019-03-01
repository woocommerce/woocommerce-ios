import UIKit
import Yosemite


// MARK: - SummaryTableViewCell
//
class SummaryTableViewCell: UITableViewCell {

    /// Label: Title
    ///
    @IBOutlet private weak var titleLabel: UILabel!

    /// Label: Creation / Update Date
    ///
    @IBOutlet private weak var createdLabel: UILabel!

    /// Label: Payment Status
    ///
    @IBOutlet private weak var paymentStatusLabel: PaddedLabel!

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
}


// MARK: - Private
//
private extension SummaryTableViewCell {

    /// Preserves the current Payment BG Color
    ///
    func preserveLabelColors(action: () -> Void) {
        let paymentColor = paymentStatusLabel.backgroundColor

        action()

        paymentStatusLabel.backgroundColor = paymentColor
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        titleLabel.applyHeadlineStyle()
        createdLabel.applyFootnoteStyle()
        paymentStatusLabel.applyPaddedLabelDefaultStyles()
    }
}
