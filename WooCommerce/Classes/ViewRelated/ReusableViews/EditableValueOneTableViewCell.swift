import UIKit

final class EditableValueOneTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!

    @IBOutlet weak var value: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        styleTitle()
        styleValue()
    }
}


private extension EditableValueOneTableViewCell {
    func styleTitle() {
        title.applyFootnoteStyle()
    }

    func styleValue() {
        value.applyBodyStyle()
    }
}
