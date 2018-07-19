import UIKit

class TwoColumnSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var leftColumn: UILabel!
    @IBOutlet private weak var rightColumn: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        tintColor = .clear
        leftColumn.applyFootnoteStyle()
        rightColumn.applyFootnoteStyle()
        leftColumn.textColor = StyleManager.sectionTitleColor
        rightColumn.textColor = StyleManager.sectionTitleColor
    }
}

extension TwoColumnSectionHeaderView {
    func configure(leftText: String?, rightText: String?) {
        leftColumn.text = leftText
        rightColumn.text = rightText
    }
}
