import UIKit

final class TitleAndEditableValueTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UITextField!
    @IBOutlet weak var button: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureAsNonSelectable()
        styleTitle()
        styleValue()
        configureButton()
    }
}


private extension TitleAndEditableValueTableViewCell {
    func configureAsNonSelectable() {
        selectionStyle = .none
    }

    func styleTitle() {
        title.applyFootnoteStyle()
    }

    func styleValue() {
        value.applyBodyStyle()
    }

    func configureButton() {
        button.isHidden = true
    }
}
