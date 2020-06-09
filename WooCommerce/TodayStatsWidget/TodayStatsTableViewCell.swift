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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureHeaderLabels()
        configureBodyLabels()
    }
}

private extension TodayStatsTableViewCell {
    
    func configureHeaderLabels() {
        visitorsHeaderLabel.applyHeadlineStyle()
        ordersHeaderLabel.applyHeadlineStyle()
        revenueHeaderLabel.applyHeadlineStyle()
    }
    
    func configureBodyLabels() {
        visitorsBodyLabel.applySecondaryBodyStyle()
        ordersBodyLabel.applySecondaryBodyStyle()
        revenueBodyLabel.applySecondaryBodyStyle()
    }
}
