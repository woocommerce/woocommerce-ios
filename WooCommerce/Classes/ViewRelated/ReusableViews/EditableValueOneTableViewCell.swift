import UIKit

final class EditableValueOneTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureAsNonSelectable()
        styleTitle()
        styleValue()
    }
}


private extension EditableValueOneTableViewCell {
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
