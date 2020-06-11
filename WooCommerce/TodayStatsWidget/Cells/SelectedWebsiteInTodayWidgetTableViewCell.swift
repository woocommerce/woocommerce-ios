import UIKit

// MARK: - SelectedWebsiteInTodayWidgetTableViewCell
//
final class SelectedWebsiteInTodayWidgetTableViewCell: UITableViewCell {

    @IBOutlet private weak var siteLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureLabels()
    }

    func configure(site: String) {
        siteLabel.text = site
    }
}

private extension SelectedWebsiteInTodayWidgetTableViewCell {

    func configureLabels() {
        siteLabel?.applyFootnoteStyle()
    }
}
