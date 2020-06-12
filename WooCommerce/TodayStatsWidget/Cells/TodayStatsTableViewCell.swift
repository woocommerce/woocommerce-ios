import UIKit

// MARK: - TodayStatsTableViewCell
//
final class TodayStatsTableViewCell: UITableViewCell {

    @IBOutlet private weak var visitorsHeaderLabel: UILabel!
    @IBOutlet private weak var visitorsBodyLabel: UILabel!
    @IBOutlet private weak var ordersHeaderLabel: UILabel!
    @IBOutlet private weak var ordersBodyLabel: UILabel!
    @IBOutlet private weak var revenueHeaderLabel: UILabel!
    @IBOutlet private weak var revenueBodyLabel: UILabel!
    @IBOutlet private weak var separator: UIImageView!
    @IBOutlet private weak var siteLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        configureHeaderLabels()
        configureBodyLabels()
        configureSeparator()
        configureSiteLabel()
    }

    func configure(visitors: String, orders: String, revenue: String, site: String) {
        visitorsBodyLabel.text = visitors
        ordersBodyLabel.text = orders
        revenueBodyLabel.text = revenue
        siteLabel.text = site
    }
}

private extension TodayStatsTableViewCell {

    func configureHeaderLabels() {
        visitorsHeaderLabel.applySubheadlineStyle()
        ordersHeaderLabel.applySubheadlineStyle()
        revenueHeaderLabel.applySubheadlineStyle()
        visitorsHeaderLabel.text = LocalizedText.visitors
        ordersHeaderLabel.text = LocalizedText.orders
        revenueHeaderLabel.text = LocalizedText.revenue
    }

    func configureBodyLabels() {
        visitorsBodyLabel.applyTitleStyle()
        ordersBodyLabel.applyTitleStyle()
        revenueBodyLabel.applyTitleStyle()
    }
    
    func configureSeparator() {
        separator.backgroundColor = .systemColor(.separator)
    }

    func configureSiteLabel() {
        siteLabel.applyFootnoteStyle()
    }
}

// Constants
//
private extension TodayStatsTableViewCell {
    enum LocalizedText {
        static let visitors = NSLocalizedString("Visitors", comment: "Visitors label in Today Stats Widget")
        static let orders = NSLocalizedString("Orders", comment: "Orders label in Today Stats Widget")
        static let revenue = NSLocalizedString("Revenue", comment: "Revenue label in Today Stats Widget")
    }
}
