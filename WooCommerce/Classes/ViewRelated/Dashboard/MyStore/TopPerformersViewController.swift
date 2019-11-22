import UIKit
import Yosemite
import XLPagerTabStrip


class TopPerformersViewController: ButtonBarPagerTabStripViewController {

    // MARK: - Properties

    @IBOutlet private weak var topBorder: UIView!
    @IBOutlet private weak var middleBorder: UIView!
    @IBOutlet private weak var headingLabel: PaddedLabel!

    private var dataVCs = [TopPerformerDataViewController]()

    // MARK: - Calculated Properties

    private var visibleChildViewController: TopPerformerDataViewController {
        return dataVCs[currentIndex]
    }

    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        configureDataViewControllers()
        configureTabStrip()
        // 👆 must be called before super.viewDidLoad()

        super.viewDidLoad()
        configureView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ensureGhostContentIsAnimated()
    }

    /// Note: Overrides this function to always trigger `updateContent()` to ensure the child view controller fills the container width.
    /// This is probably only an issue when not using `ButtonBarPagerTabStripViewController` with Storyboard.
    override func updateIfNeeded() {
        updateContent()
    }

    // MARK: - RTL support

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        /// ButtonBarView is a collection view, and it should flip to support
        /// RTL languages automatically. And yet it doesn't.
        /// So, for RTL languages, we flip it. This also flips the cells
        if traitCollection.layoutDirection == .rightToLeft {
            buttonBarView.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return dataVCs
    }

    override func configureCell(_ cell: ButtonBarViewCell, indicatorInfo: IndicatorInfo) {
        /// Hide the ImageView:
        /// We don't use it, and if / when "Ghostified" produces a quite awful placeholder UI!
        cell.imageView.isHidden = true

        /// Flip the cells back to their proper state for RTL languages.
        if traitCollection.layoutDirection == .rightToLeft {
            cell.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
    }
}


// MARK: - Public Interface
//
extension TopPerformersViewController {

    func syncTopPerformers(onCompletion: ((Error?) -> Void)? = nil) {
        let group = DispatchGroup()

        var syncError: Error? = nil

        ensureGhostContentIsDisplayed()

        dataVCs.forEach { vc in
            group.enter()
            vc.syncTopPerformers() { error in
                if let error = error {
                    syncError = error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.removeGhostContent()
            onCompletion?(syncError)
        }
    }
}


// MARK: - Placeholders
//
private extension TopPerformersViewController {

    /// Displays the Ghost Placeholder whenever there is no visible data.
    ///
    func ensureGhostContentIsDisplayed() {
        guard visibleChildViewController.hasTopEarnerStatsItems == false else {
            return
        }

        displayGhostContent()
    }

    /// Locks UI Interaction and displays Ghost Placeholder animations.
    ///
    func displayGhostContent() {
        view.isUserInteractionEnabled = false
        buttonBarView.startGhostAnimation(style: .wooDefaultGhostStyle)
        visibleChildViewController.displayGhostContent()
    }

    /// Unlocks the and removes the Placeholder Content.
    ///
    func removeGhostContent() {
        view.isUserInteractionEnabled = true
        buttonBarView.stopGhostAnimation()
        visibleChildViewController.removeGhostContent()
    }

    /// If the Ghost Content was previously onscreen, this method will restart the animations.
    ///
    func ensureGhostContentIsAnimated() {
        view.restartGhostAnimation(style: .wooDefaultGhostStyle)
    }
}


// MARK: - User Interface Configuration
//
private extension TopPerformersViewController {

    func configureView() {
        view.backgroundColor = .listBackground
        topBorder.backgroundColor = .divider
        middleBorder.backgroundColor = .divider
        buttonBarView.backgroundColor = .listForeground
        headingLabel.applyFootnoteStyle()
        headingLabel.textColor = .listIcon
        headingLabel.textInsets = Constants.headerLabelInsets
        headingLabel.text =  NSLocalizedString("Top Performers", comment: "Header label for Top Performers section of My Store tab.").uppercased()
    }

    func configureDataViewControllers() {
        let dayVC = TopPerformerDataViewController(granularity: .day)
        let weekVC = TopPerformerDataViewController(granularity: .week)
        let monthVC = TopPerformerDataViewController(granularity: .month)
        let yearVC = TopPerformerDataViewController(granularity: .year)

        dataVCs.append(dayVC)
        dataVCs.append(weekVC)
        dataVCs.append(monthVC)
        dataVCs.append(yearVC)
    }

    func configureTabStrip() {
        settings.style.buttonBarBackgroundColor = .basicBackground
        settings.style.buttonBarItemBackgroundColor = .basicBackground
        settings.style.selectedBarBackgroundColor = .primary
        settings.style.buttonBarItemFont = StyleManager.subheadlineFont
        settings.style.selectedBarHeight = TabStrip.selectedBarHeight
        settings.style.buttonBarItemTitleColor = .text
        settings.style.buttonBarItemsShouldFillAvailableWidth = false
        settings.style.buttonBarItemLeftRightMargin = TabStrip.buttonLeftRightMargin

        changeCurrentIndexProgressive = {
            (oldCell: ButtonBarViewCell?,
            newCell: ButtonBarViewCell?,
            progressPercentage: CGFloat,
            changeCurrentIndex: Bool,
            animated: Bool) -> Void in

            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .textSubtle
            newCell?.label.textColor = .primary
            oldCell?.contentView.backgroundColor = .listForeground
            newCell?.contentView.backgroundColor = .listForeground
        }
    }
}


// MARK: - Constants!
//
private extension TopPerformersViewController {
    enum Constants {
        static let headerLabelInsets = UIEdgeInsets(top: 0, left: 14, bottom: 6, right: 14)
    }

    enum TabStrip {
        static let buttonLeftRightMargin: CGFloat   = 14.0
        static let selectedBarHeight: CGFloat       = 3.0
    }
}
