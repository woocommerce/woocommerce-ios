import UIKit
import Yosemite

protocol NewOrdersDelegate {
    func didUpdateNewOrdersData(hasNewOrders: Bool)
}

class NewOrdersViewController: UIViewController {

    // MARK: - Private Properties

    @IBOutlet private weak var topBorder: UIView!
    @IBOutlet private weak var bottomBorder: UIView!
    @IBOutlet private weak var titleLabel: PaddedLabel!
    @IBOutlet private weak var descriptionLabel: PaddedLabel!
    @IBOutlet private weak var chevronImageView: UIImageView!
    @IBOutlet private weak var actionButton: UIButton!

    private var orderStatuses: [OrderStatus]? {
        didSet {
            updateNewOrdersIfNeeded(orderCount: totalPendingOrders)
        }
    }

    /// Total number of pending server-side orders
    ///
    private var totalPendingOrders: Int {
        return orderStatuses?.filter({ $0.slug == OrderStatusEnum.processing.rawValue }).map({ $0.total }).reduce(0, +) ?? 0
    }

    // MARK: - Public Properties

    public var delegate: NewOrdersDelegate?

    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureActionButtonForVoiceOver()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        calculatePreferredSize()
    }

    private func calculatePreferredSize() {
        let targetSize = CGSize(width: view.bounds.width,
                                height: UIView.layoutFittingCompressedSize.height)
        preferredContentSize = view.systemLayoutSizeFitting(targetSize)
    }
}


// MARK: - Public Interface
//
extension NewOrdersViewController {

    func syncNewOrders(onCompletion: ((Error?) -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            onCompletion?(nil)
            return
        }

        let action = OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { [weak self] (orderStatuses, error) in
            if let error = error {
                DDLogError("⛔️ Dashboard (New Orders) — Error synchronizing order statuses: \(error)")
            }

            self?.orderStatuses = orderStatuses
            onCompletion?(error)
        }

        ServiceLocator.stores.dispatch(action)
    }
}


// MARK: - Configuration
//
private extension NewOrdersViewController {

    func configureView() {
        topBorder.backgroundColor = StyleManager.wooGreyBorder
        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
        titleLabel.applyHeadlineStyle()
        titleLabel.textInsets = Constants.newOrdersTitleLabelInsets
        descriptionLabel.applyBodyStyle()
        descriptionLabel.textInsets = Constants.newOrdersDescriptionLabelInsets
        descriptionLabel.text = NSLocalizedString(
            "Review, prepare, and ship these pending orders",
            comment: "Description text used on the UI element displayed when a user has pending orders to process."
        )
        chevronImageView.image = UIImage.chevronImage.imageFlippedForRightToLeftLayoutDirection()
    }

    func configureActionButtonForVoiceOver() {
        actionButton.accessibilityLabel = descriptionLabel.text
        actionButton.accessibilityHint = titleLabel.text
    }
}


// MARK: - Actions!
//
private extension NewOrdersViewController {

    @IBAction func buttonTouchUpInside(_ sender: UIButton) {
        sender.fadeOutSelectedBackground()
        guard let pendingStatus = orderStatuses?.first(where: { $0.slug == OrderStatusEnum.processing.rawValue }) else {
            DDLogError("⛔️ Unable to display pending orders list — unable to locate pending status for current site.")
            return
        }

       ServiceLocator.analytics.track(.dashboardNewOrdersButtonTapped)
       MainTabBarController.presentOrders(statusFilter: pendingStatus)
    }

    @IBAction func buttonTouchUpOutside(_ sender: UIButton) {
        sender.fadeOutSelectedBackground()
    }

    @IBAction func buttonTouchDragOutside(_ sender: UIButton) {
        sender.fadeOutSelectedBackground()
    }

    @IBAction func buttonTouchDown(_ sender: UIButton) {
        sender.fadeInSelectedBackground()
    }
}


// MARK: - Private UIButton extension for use with NewOrdersViewController only
//
private extension UIButton {

    /// Animates the button's bg color to a selected state
    ///
    func fadeInSelectedBackground(onCompletion: (() -> Void)? = nil) {
        UIView.animate(withDuration: AnimationConstants.duration,
                       delay: 0.0,
                       options: [],
                       animations: { [weak self] in
                        self?.backgroundColor = AnimationConstants.selectedBgColor
            }, completion: { _ in
                onCompletion?()
        })
    }

    /// Animates the button's bg color to an unselected state
    ///
    func fadeOutSelectedBackground(onCompletion: (() -> Void)? = nil) {
        // Adding a "pinch" of delay here to make room for the fade-in animation to complete
        UIView.animate(withDuration: AnimationConstants.duration,
                       delay: AnimationConstants.fadeOutDelay,
                       options: [],
                       animations: { [weak self] in
                            self?.backgroundColor = .clear
            }, completion: { _ in
                onCompletion?()
        })
    }

    private enum AnimationConstants {
        static let duration: TimeInterval     = 0.1
        static let fadeOutDelay: TimeInterval = 0.06
        static let selectedBgColor            = StyleManager.wooGreyMid.withAlphaComponent(0.4)
    }
}


// MARK: - Private Helpers
//
private extension NewOrdersViewController {

    func updateNewOrdersIfNeeded(orderCount: Int) {
        let singular = NSLocalizedString(
            "You have %ld order to fulfill",
            comment: "Title text used on the My Store UI when a user has a _single_ pending order to process."
        )
        let plural = NSLocalizedString(
            "You have %ld orders to fulfill",
            comment: "Title text used on the My Store UI when a user has _multiple_ pending orders to process."
        )
        titleLabel.text = String.pluralize(orderCount, singular: singular, plural: plural)
        delegate?.didUpdateNewOrdersData(hasNewOrders: orderCount > 0)
    }
}


// MARK: - Constants!
//
private extension NewOrdersViewController {

    enum Constants {
        static let newOrdersTitleLabelInsets = UIEdgeInsets(top: 14, left: 14, bottom: 0, right: 4)
        static let newOrdersDescriptionLabelInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 4)
    }
}
