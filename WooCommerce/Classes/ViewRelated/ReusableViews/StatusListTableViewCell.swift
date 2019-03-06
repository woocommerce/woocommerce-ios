import UIKit

final class StatusListTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        textLabel?.applyBodyStyle()
        selectedBackgroundView?.backgroundColor = .clear
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        styleCheckmark()
    }

    override func prepareForReuse() {
        textLabel?.text = nil
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        accessoryType = highlighted ? .checkmark : .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        accessoryType = selected ? .checkmark : .none
    }

    private func styleCheckmark() {
        tintColor = StyleManager.wooCommerceBrandColor
    }
}
