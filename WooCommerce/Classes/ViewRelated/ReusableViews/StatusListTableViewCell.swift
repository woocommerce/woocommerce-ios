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

        configureBackground()
        styleCheckmark()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.text = nil
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        accessoryType = highlighted || isSelected ? .checkmark : .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }

    override func updateConfiguration(using state: UICellConfigurationState) {
        super.updateConfiguration(using: state)
        updateDefaultBackgroundConfiguration(using: state)
    }
}


private extension StatusListTableViewCell {
    func configureBackground() {
        configureDefaultBackgroundConfiguration()
    }

    func styleCheckmark() {
        tintColor = .primary
    }
}
