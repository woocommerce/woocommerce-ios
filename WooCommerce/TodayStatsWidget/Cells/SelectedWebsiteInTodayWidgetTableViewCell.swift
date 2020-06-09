import UIKit

// MARK: - SelectedWebsiteInTodayWidgetTableViewCell
//
final class SelectedWebsiteInTodayWidgetTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        configureLabels()
    }
    
}

private extension SelectedWebsiteInTodayWidgetTableViewCell {
    
    func configureLabels() {
        textLabel?.applyBodyStyle()
    }
}
