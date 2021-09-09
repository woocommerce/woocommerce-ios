import UIKit

final class LabelAndButtonTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var button: UIButton!

    // TODO: Private outlets, configure method
    // TODO: Button completion

    override func awakeFromNib() {
        super.awakeFromNib()
        configureButton()
    }
}

private extension LabelAndButtonTableViewCell {
    func configureButton() {
        button.tintColor = .accent
    }
}
