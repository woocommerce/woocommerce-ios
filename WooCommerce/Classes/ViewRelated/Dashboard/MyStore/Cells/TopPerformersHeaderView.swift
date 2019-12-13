import UIKit


/// Renders a section header for top performers with a main description label and two column labels [Left / Right].
///
class TopPerformersHeaderView: UITableViewHeaderFooterView {

    /// Main Description Label
    ///
    @IBOutlet private weak var descriptionLabel: UILabel!

    /// Left Label
    ///
    @IBOutlet private weak var leftColumn: UILabel!

    /// Right Label
    ///
    @IBOutlet private weak var rightColumn: UILabel!

    /// Bottom Border View
    ///
    @IBOutlet private weak var borderView: UIView!

    /// Description Label's Text
    ///
    var descriptionText: String? {
        get {
            return descriptionLabel.text
        }
        set {
            descriptionLabel.text = newValue
        }
    }

    /// Left Label's Text
    ///
    var leftText: String? {
        get {
            return leftColumn.text
        }
        set {
            leftColumn.text = newValue
        }
    }

    /// Right Label's Text
    ///
    var rightText: String? {
        get {
            return rightColumn.text
        }
        set {
            rightColumn.text = newValue
        }
    }

    // MARK: - Initialization

    override func awakeFromNib() {
        super.awakeFromNib()
        descriptionLabel.applyBodyStyle()
        leftColumn.applyFootnoteStyle()
        rightColumn.applyFootnoteStyle()
        leftColumn.textColor = .listIcon
        rightColumn.textColor = .listIcon
        borderView.backgroundColor = .systemColor(.separator)
        contentView.backgroundColor = .listForeground
    }
}


// MARK: - Public Methods
//
extension TopPerformersHeaderView {
    func configure(descriptionText: String?, leftText: String?, rightText: String?) {
        descriptionLabel.text = descriptionText
        leftColumn.text = leftText
        rightColumn.text = rightText
    }
}
