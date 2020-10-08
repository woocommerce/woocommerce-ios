import Foundation
import UIKit
import Yosemite


/// ProductLoaderViewController: Loads asynchronously a Product (given it's ProductID + SiteID).
/// On Success the ProductDetailsViewController will be rendered "in place".
///
final class ProductLoaderViewController: UIViewController {
    enum Model: Equatable {
        case product(productID: Int64)
        case productVariation(productID: Int64, variationID: Int64)
    }

    /// UI Spinner
    ///
    private let activityIndicator = UIActivityIndicatorView(style: .gray)

    /// Target model (Product/ProductVariation ID)
    ///
    private let model: Model

    /// Target Product's SiteID
    ///
    private let siteID: Int64

    /// Force the product detail to be presented in read only mode
    ///
    private let forceReadOnly: Bool

    /// UI Active State
    ///
    private var state: State = .loading {
        didSet {
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    // MARK: - Initializers

    init(model: Model, siteID: Int64, forceReadOnly: Bool) {
        self.model = model
        self.siteID = siteID
        self.forceReadOnly = forceReadOnly

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
        addCloseNavigationBarButton()
        loadModel()
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
}


// MARK: - Actions
//
private extension ProductLoaderViewController {
    func loadModel() {
        switch model {
        case .product(let productID):
            loadProduct(productID: productID)
        case .productVariation(let productID, let variationID):
            loadProductVariation(productID: productID, variationID: variationID)
        }
    }

    /// Loads (and displays) the specified Product.
    ///
    func loadProduct(productID: Int64) {
        let action = ProductAction.retrieveProduct(siteID: siteID, productID: productID) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let product):
                self.state = .productLoaded(product: product)
            case .failure(let error):
                DDLogError("⛔️ Error loading Product for siteID: \(self.siteID) productID:\(self.productID) error:\(error)")
                self.state = .failure
            }
        }

        state = .loading
        ServiceLocator.stores.dispatch(action)
    }

    /// Loads (and displays) the specified ProductVariation.
    ///
    func loadProductVariation(productID: Int64, variationID: Int64) {
        state = .loading

        let group = DispatchGroup()

        var parentProduct: Product?
        var productVariation: ProductVariation?

        group.enter()
        let productVariationAction = ProductVariationAction.retrieveProductVariation(siteID: siteID,
                                                                     productID: productID,
                                                                     variationID: variationID) { result in
                                                                        switch result {
                                                                        case .success(let productVariationResult):
                                                                            productVariation = productVariationResult
                                                                        case .failure:
                                                                            break
                                                                        }
                                                                        group.leave()

        }
        ServiceLocator.stores.dispatch(productVariationAction)

        group.enter()
        let productAction = ProductAction.retrieveProduct(siteID: siteID, productID: productID) { (product, error) in
            parentProduct = product
            group.leave()
        }
        ServiceLocator.stores.dispatch(productAction)

        group.notify(queue: .main) { [weak self] in
            guard let self = self else {
                return
            }

            guard let parentProduct = parentProduct, let productVariation = productVariation else {
                DDLogError("⛔️ Error loading ProductVariation & Product for siteID: \(self.siteID) productID:\(productID) variationID:\(variationID)")
                self.state = .failure
                return
            }

            self.state = .productVariationLoaded(productVariation: productVariation, parentProduct: parentProduct)
        }
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
            self?.loadModel()
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

    /// Presents the ProductDetailsViewController or the ProductFormViewController, as a childViewController, for a given Product.
    ///
    func presentProductDetails(for product: Product) {
        ProductDetailsFactory.productDetails(product: product,
                                             presentationStyle: .contained(containerViewController: self),
                                             forceReadOnly: forceReadOnly) { [weak self] viewController in
            self?.attachProductDetailsChildViewController(viewController)
        }
    }

    /// Presents the ProductDetailsViewController or the ProductFormViewController, as a childViewController, for a given Product.
    ///
    func presentProductVariationDetails(for productVariation: ProductVariation, parentProduct: Product) {
        ProductVariationDetailsFactory.productVariationDetails(productVariation: productVariation,
                                                               parentProduct: parentProduct,
                                                               presentationStyle: .contained(containerViewController: self),
                                                               forceReadOnly: forceReadOnly) { [weak self] viewController in
            self?.attachProductDetailsChildViewController(viewController)
        }
    }

    func attachProductDetailsChildViewController(_ viewController: UIViewController) {
        // Attach
        addChild(viewController)
        attachSubview(viewController.view)
        viewController.didMove(toParent: self)

        // And, of course, borrow the Child's Title + right nav bar items
        title = viewController.navigationItem.title
        navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
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
        case .productLoaded(let product):
            presentProductDetails(for: product)
        case .productVariationLoaded(let productVariation, let parentProduct):
            presentProductVariationDetails(for: productVariation, parentProduct: parentProduct)
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
        case .productLoaded, .productVariationLoaded:
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
    case productLoaded(product: Product)
    case productVariationLoaded(productVariation: ProductVariation, parentProduct: Product)
    case failure
}
