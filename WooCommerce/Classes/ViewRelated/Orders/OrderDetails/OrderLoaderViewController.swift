import Foundation
import UIKit
import Yosemite


// MARK: - OrderLoaderViewController: Loads asynchronously an Order (given it's OrderID + SiteID).
//         On Success the OrderDetailsViewController will be rendered "in place".
//
class OrderLoaderViewController: UIViewController {

    /// UI Spinner
    ///
    private let activityIndicator = UIActivityIndicatorView(style: .gray)

    /// Target OrderID
    ///
    private let orderID: Int

    /// Target Order's SiteID
    ///
    private let siteID: Int

    /// UI Active State
    ///
    private var state: State = .loading {
        didSet {
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }


    // MARK: - Initializers

    init(orderID: Int, siteID: Int) {
        self.orderID = orderID
        self.siteID = siteID

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Please specify the OrderID and SiteID!")
    }


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItem()
        configureSpinner()
        configureMainView()

        reloadOrder()
    }
}


// MARK: - Actions
//
private extension OrderLoaderViewController {

    /// Loads (and displays) the specified Order.
    ///
    func reloadOrder() {
        let action = OrderAction.retrieveOrder(siteID: siteID, orderID: orderID) { [weak self] (order, error) in
            guard let `self` = self else {
                return
            }

            guard let order = order else {
                DDLogError("## Error loading Order \(self.siteID).\(self.orderID): \(error.debugDescription)")
                self.state = .failure
                return
            }

            self.state = .success(order: order)
        }

        state = .loading
        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Configuration
//
private extension OrderLoaderViewController {

    /// Setup: Navigation
    ///
    func configureNavigationItem() {
        title = NSLocalizedString("Loading Order", comment: "Displayed when an Order is being retrieved")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)
    }

    /// Setup: Spinner
    ///
    func configureSpinner() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    }
}


// MARK: - Overlays
//
private extension OrderLoaderViewController {

    /// Starts the Spinner
    ///
    func startSpinner() {
        activityIndicator.startAnimating()
    }

    /// Stops the Spinner
    ///
    func stopSpinner() {
        activityIndicator.stopAnimating()
    }

    /// Displays the Loading Overlay.
    ///
    func displayFailureOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = .waitingForCustomersImage
        overlayView.messageText = NSLocalizedString("The Order couldn't be loaded!", comment: "Fetching an Order Failed")
        overlayView.actionText = NSLocalizedString("Retry", comment: "Retry the last action")
        overlayView.onAction = { [weak self] in
            self?.reloadOrder()
        }

        overlayView.attach(to: view)
    }

    /// Removes all of the the OverlayMessageView instances in the view hierarchy.
    ///
    func removeAllOverlays() {
        for subview in view.subviews where subview is OverlayMessageView {
            subview.removeFromSuperview()
        }
    }

    /// Presents the OrderDetailsViewController, as a childViewController, for a given Order.
    ///
    func presentOrderDetails(for order: Order) {
        let identifier = OrderDetailsViewController.classNameWithoutNamespaces
        guard let detailsViewController = UIStoryboard.orders.instantiateViewController(withIdentifier: identifier) as? OrderDetailsViewController else {
            fatalError()
        }

        // Setup the DetailsViewController
        detailsViewController.viewModel = OrderDetailsViewModel(order: order)

        // Attach
        addChild(detailsViewController)
        attachSubview(detailsViewController.view)
        detailsViewController.didMove(toParent: self)

        // And, of course, borrow the Child's Title
        title = detailsViewController.title
    }

    /// Removes all of the children UIViewControllers
    ///
    func detachChildrenViewControllers() {
        for child in children {
            child.view.removeFromSuperview()
            child.removeFromParent()
            child.didMove(toParent: nil)
        }
    }
}


// MARK: - UI Methods
//
private extension OrderLoaderViewController {

    /// Attaches a given Subview, and ensures it's pinned to all the edges
    ///
    func attachSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)
        view.pinSubviewToAllEdges(subview)
    }
}


// MARK: - Finite State Machine Management
//
private extension OrderLoaderViewController {

    /// Runs whenever the FSM enters a State.
    ///
    func didEnter(state: State) {
        switch state {
        case .loading:
            startSpinner()
        case .success(let order):
            presentOrderDetails(for: order)
        case .failure:
            displayFailureOverlay()
        }
    }

    /// Runs whenever the FSM leaves a State.
    ///
    func didLeave(state: State) {
        switch state {
        case .loading:
            stopSpinner()
        case .success(_):
            detachChildrenViewControllers()
        case .failure:
            removeAllOverlays()
        }
    }
}


// MARK: - OrderLoader Possible Status(es)
//
private enum State {
    case loading
    case success(order: Order)
    case failure
}
