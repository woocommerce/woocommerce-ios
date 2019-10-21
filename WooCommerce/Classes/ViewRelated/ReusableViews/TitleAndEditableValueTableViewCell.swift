import UIKit

final class TitleAndEditableValueTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureAsNonSelectable()
        styleTitle()
        styleValue()
    }
}


extension TitleAndEditableValueTableViewCell {
    fileprivate func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    fileprivate func configureAsNonSelectable() {
        selectionStyle = .none
    }

    fileprivate func styleTitle() {
        title.applyFootnoteStyle()
    }

    fileprivate func styleValue() {
        value.applyBodyStyle()
    }
}
