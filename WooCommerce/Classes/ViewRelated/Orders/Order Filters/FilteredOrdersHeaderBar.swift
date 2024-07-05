import UIKit

/// A view with a title on the left side, and tappable component on the right side showing how many filters are applied to the order list.
/// Used on top of the Order List screen.
///
final class FilteredOrdersHeaderBar: UIView {

    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var lastUpdatedLabel: UILabel!
    @IBOutlet private weak var filterButton: UIButton!

    private let bottomBorder = CALayer()

    /// The number of filters applied
    ///
    private var numberOfFilters = 0

    /// The time when the orders where updated
    ///
    private var lastUpdatedText = ""

    var onAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        configureLabels()
        configureButtons()
        configureBackground()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        adjustBorderOnFrameUpdate()
    }

    func setNumberOfFilters(_ filters: Int) {
        numberOfFilters = filters
        configureLabels()
        configureButtons()
    }

    func setLastUpdatedTime(_ time: String) {
        lastUpdatedText = time
        configureLabels()
    }

    @IBAction private func filterButtonTapped(_ sender: Any) {
        onAction?()
    }

}

// MARK: - Setup
private extension FilteredOrdersHeaderBar {
    func configureBackground() {
        backgroundColor = .listForeground(modal: false)
        bottomBorder.backgroundColor = UIColor.divider.cgColor
        layer.addSublayer(bottomBorder)
    }

    /// Adjusts the bottom border whenever the view's frame changes after initial layout setup
    ///
    func adjustBorderOnFrameUpdate() {
        let borderWidth = 0.5
        bottomBorder.frame = CGRect(x: 0,
                                    y: bounds.height - borderWidth,
                                    width: bounds.width,
                                    height: borderWidth)
    }

    /// Setup: Labels
    ///
    func configureLabels() {
        mainLabel.applyHeadlineStyle()
        mainLabel.text = numberOfFilters == 0 ? Localization.noFiltersApplied : Localization.filtersApplied

        lastUpdatedLabel.applySecondaryFootnoteStyle()
        lastUpdatedLabel.text = Localization.lastUpdatedText(time: lastUpdatedText)
        lastUpdatedLabel.isHidden = lastUpdatedText.isEmpty
    }

    /// Setup: Buttons
    ///
    func configureButtons() {
        filterButton.applyLinkButtonStyle()
        let title =  numberOfFilters == 0 ?
        Localization.buttonWithoutActiveFilters :
        String.localizedStringWithFormat(Localization.buttonWithActiveFilters, numberOfFilters)

        filterButton.setTitle(title, for: .normal)
        var configuration = UIButton.Configuration.filled()
        configuration.contentInsets = .init(.zero)
        filterButton.accessibilityIdentifier = "orders-filter-button"
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
        static func lastUpdatedText(time: String) -> String {
            let format = NSLocalizedString("Last Updated: %@", comment: "Time for when the orders were last updated")
            return String.localizedStringWithFormat(format, time)
        }
    }
}
