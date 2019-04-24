import UIKit

final class TitleAndEditableValueTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var value: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureAsNonSelectable()
        styleTitle()
        styleValue()
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
}

extension TitleAndEditableValueTableViewCell {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            print("==== font size changed ")
        }
    }
}
