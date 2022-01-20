import UIKit

final class TitleAndSubtitleTableViewCell: UITableViewCell {

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

private extension TitleAndSubtitleTableViewCell {
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
    }
}
