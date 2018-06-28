import UIKit

class TwoColumnSectionHeaderView: UITableViewHeaderFooterView {
    @IBOutlet private weak var leftColumn: UILabel!
    @IBOutlet private weak var rightColumn: UILabel!

    static let reuseIdentifier = "TwoColumnSectionHeaderView"

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    class func makeFromNib() -> TwoColumnSectionHeaderView {
        return Bundle.main.loadNibNamed("TwoColumnSectionHeaderView", owner: self, options: nil)?.first as! TwoColumnSectionHeaderView
    }

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
