import UIKit

final class TitleAndSubtitleAndStatusTableViewCell: UITableViewCell {

    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var statusContainerView: UIView!
    @IBOutlet var statusLabel: PaddedLabel!

    static func register(for tableView: UITableView) {
        tableView.registerNib(for: self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

// MARK: - Setup

private extension TitleAndSubtitleAndStatusTableViewCell {
    func configureBackground() {
        backgroundColor = .listForeground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = .listBackground
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        subtitleLabel.applyCaption1Style()
        titleLabel.applyBodyStyle()
        statusLabel.applyFootnoteStyle()
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .black // constant because there will always background color on the label
        statusLabel.layer.cornerRadius = 2.0
        statusLabel.layer.masksToBounds = true
    }
}
