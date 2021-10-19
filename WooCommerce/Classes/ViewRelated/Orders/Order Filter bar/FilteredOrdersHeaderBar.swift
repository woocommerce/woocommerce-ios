import UIKit

/// A view with a title on the left side, and tappable component on the right side showing how many filters are applied to the order list.
/// Used on top of the Order List screen.
///
final class FilteredOrdersHeaderBar: UIView {

    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var filtersButtonLabel: UILabel!
    @IBOutlet private weak var filtersNumberLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureLabels()
    }


}

// MARK: - Setup

private extension FilteredOrdersHeaderBar {
    func configureBackground() {
        backgroundColor = .listForeground
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        mainLabel.applyHeadlineStyle()
        filtersButtonLabel.applySubheadlineStyle()
        filtersNumberLabel.applyFootnoteStyle()
    }
}
