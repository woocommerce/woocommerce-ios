import UIKit

/// A view with a title on the left side, and tappable component on the right side showing how many filters are applied to the order list.
/// Used on top of the Order List screen.
///
final class FilteredOrdersHeaderBar: UIView {

    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var filterButton: UIButton!

    /// The number of filters applied
    ///
    private var numberOfFilters = 4

    var onAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        configureButtons()
    }

    func setNumberOfFilters(_ filters: Int) {
        numberOfFilters = filters
        configureLabels()
        configureButtons()
    }

    @IBAction private func filterButtonTapped(_ sender: Any) {
        onAction?()
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
        mainLabel.text = numberOfFilters == 0 ? Localization.noFiltersApplied : Localization.filtersApplied
    }

    /// Setup: Buttons
    ///
    func configureButtons() {
        filterButton.applyLinkButtonStyle()
        let title =  numberOfFilters == 0 ?
        Localization.buttonWithoutActiveFilters :
        String.localizedStringWithFormat(Localization.buttonWithActiveFilters, numberOfFilters)

        filterButton.setTitle(title, for: .normal)
        filterButton.contentEdgeInsets = .zero
    }

    enum Localization {
        static let noFiltersApplied = NSLocalizedString("All Orders",
                                                        comment: "Header bar label on top of order list when no filters are applied")
        static let filtersApplied = NSLocalizedString("Filtered Orders",
                                                      comment: "Header bar label on top of order list when filters are applied")
        static let filters = NSLocalizedString("Filters",
                                               comment: "Filters button text on header bar on top of order list")
        static let buttonWithoutActiveFilters =
            NSLocalizedString("Filter",
                              comment: "Title of the toolbar button to filter orders without filters applied.")
        static let buttonWithActiveFilters =
            NSLocalizedString("Filter (%ld)",
                              comment: "Title of the toolbar button to filter orders with filters applied.")
    }
}
