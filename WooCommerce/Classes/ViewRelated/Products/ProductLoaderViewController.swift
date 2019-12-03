import Foundation
import UIKit
import Yosemite


/// ProductLoaderViewController: Loads asynchronously a Product (given it's ProductID + SiteID).
/// On Success the ProductDetailsViewController will be rendered "in place".
///
final class ProductLoaderViewController: UIViewController {

    /// UI Spinner
    ///
    private let activityIndicator = UIActivityIndicatorView(style: .gray)

    /// Target ProductID
    ///
    private let productID: Int

    /// Target Product's SiteID
    ///
    private let siteID: Int

    /// The Target Product's Currency
    ///
    private let currency: String

    /// UI Active State
    ///
    private var state: State = .loading {
        didSet {
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    // MARK: - Initializers

    init(productID: Int, siteID: Int, currency: String) {
        self.productID = productID
        self.siteID = siteID
        self.currency = currency

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Please specify the ProductID and SiteID!")
    }


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationTitle()
        configureSpinner()
        configureMainView()
        configureDismissButton()
        loadProduct()
    }
}


// MARK: - Configuration
//
private extension ProductLoaderViewController {

    /// Setup: Navigation Title
    ///
    func configureNavigationTitle() {
        title = NSLocalizedString("Loading Product", comment: "Displayed when an Product is being retrieved")
    }

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
        view.addSubview(activityIndicator)
        view.pinSubviewAtCenter(activityIndicator)
    }

    /// Setup: Spinner
    ///
    func configureSpinner() {
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    }

    /// Setup: Dismiss Button
    ///
    func configureDismissButton() {
        let dismissButtonTitle = NSLocalizedString("Dismiss", comment: "Product details screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        navigationItem.setLeftBarButton(leftBarButton, animated: false)
    }
}


// MARK: - Actions
//
private extension ProductLoaderViewController {

    /// Loads (and displays) the specified Product.
    ///
    func loadProduct() {
        let action = ProductAction.retrieveProduct(siteID: siteID, productID: productID) { [weak self] (product, error) in
            guard let self = self else {
                return
            }

            guard let product = product else {
                DDLogError("⛔️ Error loading Product for siteID: \(self.siteID) productID:\(self.productID) error:\(error.debugDescription)")
                self.state = .failure
                return
            }

            self.state = .success(product: product)
        }

        state = .loading
        ServiceLocator.stores.dispatch(action)
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - Overlays
//
private extension ProductLoaderViewController {

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
        overlayView.messageText = NSLocalizedString("This product couldn't be loaded", comment: "Message displayed when loading a specific product fails")
        overlayView.actionText = NSLocalizedString("Retry", comment: "Retry the last action")
        overlayView.onAction = { [weak self] in
            self?.loadProduct()
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

    /// Presents the ProductDetailsViewController, as a childViewController, for a given Product.
    ///
    func presentProductDetails(for product: Product) {
        let detailsViewModel = ProductDetailsViewModel(product: product, currency: currency)
        let detailsViewController = ProductDetailsViewController(viewModel: detailsViewModel)

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
private extension ProductLoaderViewController {

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
private extension ProductLoaderViewController {

    /// Runs whenever the FSM enters a State.
    ///
    func didEnter(state: State) {
        switch state {
        case .loading:
            startSpinner()
        case .success(let product):
            presentProductDetails(for: product)
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
        case .success:
            detachChildrenViewControllers()
        case .failure:
            removeAllOverlays()
        }
    }
}


// MARK: - ProductLoader Possible States
//
private enum State {
    case loading
    case success(product: Product)
    case failure
}
