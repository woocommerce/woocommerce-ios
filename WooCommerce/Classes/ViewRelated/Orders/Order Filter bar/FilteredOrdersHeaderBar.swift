import UIKit

/// A view with a title on the left side, and tappable component on the right side showing how many filters are applied to the order list.
/// Used on top of the Order List screen.
///
final class FilteredOrdersHeaderBar: UIView {

    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var filtersView: UIView!
    @IBOutlet private weak var filtersButtonLabel: UILabel!
    @IBOutlet private weak var filtersNumberLabel: UILabel!

    /// The number of filters applied
    ///
    private var numberOfFilters = 0

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureFiltersView()
        configureLabels()
    }

    func setNumberOfFilters(_ filters: Int) {
        numberOfFilters = filters
        configureLabels()
    }
}

// MARK: - Setup

private extension FilteredOrdersHeaderBar {
    func configureBackground() {
        backgroundColor = .listForeground
    }

    func configureFiltersView() {
        filtersView.layer.cornerRadius = 14.0
        filtersView.layer.borderWidth = 1.0
        filtersView.layer.borderColor = UIColor.secondaryButtonBorder.cgColor
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        mainLabel.applyHeadlineStyle()
        mainLabel.text = numberOfFilters == 0 ? Localization.noFiltersApplied : Localization.filtersApplied
        filtersButtonLabel.applySubheadlineStyle()
        filtersButtonLabel.text = Localization.filters
        filtersNumberLabel.applyFootnoteStyle()
        filtersNumberLabel.isHidden = numberOfFilters == 0
        filtersNumberLabel.text = "\(numberOfFilters)"
    }

    enum Localization {
        static let noFiltersApplied = NSLocalizedString("All Orders",
                                                        comment: "Header bar label on top of order list when no filters are applied")
        static let filtersApplied = NSLocalizedString("Filtered Orders",
                                                      comment: "Header bar label on top of order list when filters are applied")
        static let filters = NSLocalizedString("Filters",
                                               comment: "Filters button text on header bar on top of order list")
    }
}
