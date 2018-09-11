import UIKit
import Yosemite
import CocoaLumberjack

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

    /// ResultsController: Loads Orders with status `Processing` from the Storage Layer
    ///
    private lazy var resultsController: ResultsController<StorageOrder> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "status = %@", OrderStatus.processing.rawValue)
        let descriptor = NSSortDescriptor(key: "orderID", ascending: true)
        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    // MARK: - Public Properties

    public var delegate: NewOrdersDelegate?

    // MARK: - View Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureResultsController()
    }
}


// MARK: - Public Interface
//
extension NewOrdersViewController {

    func syncNewOrders() {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            return
        }

        let action = OrderAction.synchronizeOrders(siteID: siteID, pageNumber: Syncing.pageNumber, pageSize: Syncing.pageSize) { error in
            if let error = error {
                DDLogError("⛔️ Dashboard (New Orders) — Error synchronizing orders: \(error)")
            }
        }

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Configuration
//
private extension NewOrdersViewController {

    func configureView() {
        view.backgroundColor = StyleManager.wooWhite
        topBorder.backgroundColor = StyleManager.wooGreyBorder
        bottomBorder.backgroundColor = StyleManager.wooGreyBorder
        titleLabel.applyHeadlineStyle()
        titleLabel.textInsets = Constants.newOrdersTitleLabelInsets
        descriptionLabel.applyBodyStyle()
        descriptionLabel.textInsets = Constants.newOrdersDescriptionLabelInsets
        descriptionLabel.text = NSLocalizedString("Review, prepare, and ship these pending orders",
                                                  comment: "Description text used on the UI element displayed when a user has pending orders to process.")
        chevronImageView.image = UIImage.chevronImage
    }

    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateNewOrdersIfNeeded()
        }
        try? resultsController.performFetch()
    }
}


// MARK: - Actions!
//
private extension NewOrdersViewController {

    @IBAction func buttonTouchUpInside(_ sender: UIButton) {
        sender.fadeOutSelectedBackground {
            MainTabBarController.switchToOrdersTab()
        }
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
    func updateNewOrdersIfNeeded() {
        let currentCount = resultsController.fetchedObjects.count
        titleLabel.text = String.pluralize(currentCount,
                                    singular: NSLocalizedString("You have %ld order to fulfill", comment: "Title text used on the My Store UI when a user has a _single_ pending order to process."),
                                    plural: NSLocalizedString("You have %ld orders to fulfill", comment: "Title text used on the My Store UI when a user has _multiple_ pending orders to process."))
        delegate?.didUpdateNewOrdersData(hasNewOrders: currentCount > 0)
    }
}


// MARK: - Constants!
//
private extension NewOrdersViewController {
    enum Constants {
        static let newOrdersTitleLabelInsets = UIEdgeInsets(top: 14, left: 14, bottom: 0, right: 4)
        static let newOrdersDescriptionLabelInsets = UIEdgeInsets(top: 4, left: 14, bottom: 0, right: 4)
    }

    enum Syncing {
        static let pageNumber = 1
        static let pageSize = 40
    }
}
