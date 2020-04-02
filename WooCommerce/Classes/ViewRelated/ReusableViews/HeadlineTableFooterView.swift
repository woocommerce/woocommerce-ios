import UIKit

final class FootnoteTableFooterView: UIView {

    @IBOutlet weak var footnoteLabel: UILabel!

    static let reuseIdentifier = "HeadlineTableFooterView"

    override func awakeFromNib() {
        super.awakeFromNib()

        setupHeadlineLabel()
    }


}

// MARK: - Public methods
//
extension FootnoteTableFooterView {
    /// Initialization method for footnote label
    ///
    func setupHeadlineLabel() {
        footnoteLabel.applyFootnoteStyle()
        footnoteLabel.numberOfLines = 0
    }
}
