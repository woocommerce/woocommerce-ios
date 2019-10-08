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


private extension TitleAndEditableValueTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureAsNonSelectable() {
        selectionStyle = .none
    }

    func styleTitle() {
        title.applyFootnoteStyle()
    }

    func styleValue() {
        value.applyBodyStyle()
    }
}
