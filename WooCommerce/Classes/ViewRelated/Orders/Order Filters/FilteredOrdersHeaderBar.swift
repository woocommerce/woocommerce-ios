import UIKit

/// A view with a title on the left side, and tappable component on the right side showing how many filters are applied to the order list.
/// Used on top of the Order List screen.
///
@MainActor
final class FilteredOrdersHeaderBar: UIView {

    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var lastUpdatedLabel: UILabel!
    @IBOutlet private weak var filterButton: UIButton! {
        didSet {
            if #available(iOS 26.0, *) {
                OrdersProductsListHeaderStyle.configureButtonSizing(filterButton)
            }
        }
    }
    @IBOutlet weak var headerBarLayoutStackView: UIStackView!

    private let bottomBorder = CALayer()

    /// Retains the content trait registration token, so it's not deallocated immediately
    ///
    // periphery: ignore - False negative. Perhaps does not catch non-direct reads?
    private var contentSizeTraitRegistration: UITraitChangeRegistration?

    /// The number of filters applied
    ///
    private var numberOfFilters = 0

    /// The time when the orders where updated
    ///
    private var lastUpdatedText = ""

    var onAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        // UIKit invokes awakeFromNib on the main thread, but the imported override is nonisolated.
        MainActor.assumeIsolated {
            configureLabels()
            configureButtons()
            configureBackground()
            updateStackViewAxis(for: traitCollection)
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if newSuperview != nil {
            contentSizeTraitRegistration = registerForTraitChanges([
                UITraitPreferredContentSizeCategory.self
            ]) { [weak self] (_: FilteredOrdersHeaderBar, _: UITraitCollection) in
                guard let self else { return }
                self.updateStackViewAxis(for: self.traitCollection)
            }
        } else {
            contentSizeTraitRegistration = nil
        }
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
// MARK: - Dynamic type support
/// The `Last updated: time` tends to get truncated at larger text sizes by the filter button.
/// Laying out the overall stack view vertically avoids this with accessibility sizes.
extension FilteredOrdersHeaderBar {
    private func updateStackViewAxis(for traitCollection: UITraitCollection) {
        let isAccessibilitySize = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        headerBarLayoutStackView.axis = isAccessibilitySize ? .vertical : .horizontal
        if #available(iOS 26.0, *) {
            headerBarLayoutStackView.alignment = isAccessibilitySize ? .leading : .center
        } else {
            headerBarLayoutStackView.alignment = .fill
        }
    }
}

// MARK: - Setup
private extension FilteredOrdersHeaderBar {
    func configureBackground() {
        if #available(iOS 26.0, *) {
            backgroundColor = .clear
            bottomBorder.backgroundColor = UIColor.clear.cgColor
        } else {
            backgroundColor = .listForeground(modal: false)
            bottomBorder.backgroundColor = UIColor.divider.cgColor
        }
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
        mainLabel.text = numberOfFilters == 0 ? OrderListLocalization.allOrdersHeaderTitle : OrderListLocalization.filteredOrdersHeaderTitle

        lastUpdatedLabel.applySecondaryFootnoteStyle()
        lastUpdatedLabel.text = OrderListLocalization.lastUpdatedText(time: lastUpdatedText)
        lastUpdatedLabel.isHidden = lastUpdatedText.isEmpty
    }

    /// Setup: Buttons
    ///
    func configureButtons() {
        let title = OrderListLocalization.filterButtonTitle(activeFilterCount: numberOfFilters)

        if #available(iOS 26.0, *) {
            var configuration = UIButton.Configuration.glass()
            configuration.buttonSize = .medium
            configuration.title = title
            configuration.baseForegroundColor = .label
            filterButton.configuration = configuration
            filterButton.setContentHuggingPriority(.required, for: .horizontal)
        } else {
            filterButton.applyLinkButtonStyle()
        }
        filterButton.setTitle(title, for: .normal)
        filterButton.accessibilityIdentifier = "orders-filter-button"
    }
}
