import UIKit

class DefaultStyleTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel?.applyBodyStyle()
        textLabel?.adjustsFontSizeToFitWidth = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(with viewModel: ContactViewModel) {
        accessoryView = viewModel.iconView
        textLabel?.text = viewModel.text
    }
}
