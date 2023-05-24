import UIKit
import Yosemite
import WooFoundation
import protocol Storage.StorageManagerType
import class Networking.ProductsRemote

/// Controls navigation for the flow to add a product given a navigation controller.
/// This class is not meant to be retained so that its life cycle is throughout the navigation. Example usage:
///
/// let coordinator = AddProductCoordinator(...)
/// coordinator.start()
///
final class AddProductCoordinator: Coordinator {
    /// Navigation source to the add product flow.
    enum Source {
        /// Initiated from the products tab.
        case productsTab
        /// Initiated from the product onboarding card in the dashboard.
        case productOnboarding
        /// Initiated from the store onboarding card in the dashboard.
        case storeOnboarding
    }

    let navigationController: UINavigationController

    private let siteID: Int64
    private let source: Source
    private let sourceBarButtonItem: UIBarButtonItem?
    private let sourceView: UIView?
    private let productImageUploader: ProductImageUploaderProtocol
    private let storage: StorageManagerType
    private let stores: StoresManager
    private let isFirstProduct: Bool

    /// ResultController to to track the current product count.
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let predicate = \StorageProduct.siteID == siteID
        let controller = ResultsController<StorageProduct>(storageManager: storage, matching: predicate, sortedBy: [])
        try? controller.performFetch()
        return controller
    }()

    /// Assign this closure to be notified when a new product is saved remotely
    ///
    var onProductCreated: (Product) -> Void = { _ in }

    init(siteID: Int64,
         source: Source,
         sourceBarButtonItem: UIBarButtonItem,
         sourceNavigationController: UINavigationController,
         storage: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
         isFirstProduct: Bool) {
        self.siteID = siteID
        self.source = source
        self.sourceBarButtonItem = sourceBarButtonItem
        self.sourceView = nil
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.storage = storage
        self.stores = stores
        self.isFirstProduct = isFirstProduct
    }

    init(siteID: Int64,
         source: Source,
         sourceView: UIView?,
         sourceNavigationController: UINavigationController,
         storage: StorageManagerType = ServiceLocator.storageManager,
         stores: StoresManager = ServiceLocator.stores,
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
         isFirstProduct: Bool) {
        self.siteID = siteID
        self.source = source
        self.sourceBarButtonItem = nil
        self.sourceView = sourceView
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.storage = storage
        self.stores = stores
        self.isFirstProduct = isFirstProduct
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        switch source {
        case .productsTab, .productOnboarding:
            ServiceLocator.analytics.track(event: .ProductsOnboarding.productListAddProductButtonTapped(templateEligible: isTemplateOptionsEligible()))
        default:
            break
        }

        if shouldPresentProductCreationBottomSheet() {
            presentProductCreationTypeBottomSheet()
        } else {
            presentProductTypeBottomSheet(creationType: .manual)
        }
    }
}

// MARK: Navigation
private extension AddProductCoordinator {

    /// Defines if the product creation bottom sheet should be presented.
    /// Currently returns `true` when the store is eligible for displaying template options.
    ///
    func shouldPresentProductCreationBottomSheet() -> Bool {
        isTemplateOptionsEligible()
    }

    /// Returns `true` when the number of products is fewer than 3.
    ///
    func isTemplateOptionsEligible() -> Bool {
        productsResultsController.numberOfObjects < 3
    }

    /// Returns `true` when there are existing products.
    ///
    func shouldShowGroupedProductType() -> Bool {
        !productsResultsController.isEmpty
    }

    /// Presents a bottom sheet for users to choose if they want a create a product manually or via a template.
    ///
    func presentProductCreationTypeBottomSheet() {
        let title = NSLocalizedString("Add a product",
                                      comment: "Message title of bottom sheet for selecting a template or manual product")
        let subtitle = NSLocalizedString("How do you want to start?",
                                         comment: "Message subtitle of bottom sheet for selecting a template or manual product")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title, subtitle: subtitle)
        let command = ProductCreationTypeSelectorCommand { selectedCreationType in
            self.trackProductCreationType(selectedCreationType)
            self.presentProductTypeBottomSheet(creationType: selectedCreationType)
        }
        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
        productTypesListPresenter.show(from: navigationController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem, arrowDirections: .any)
    }

    /// Presents a bottom sheet for users to choose if what kind of product they want to create.
    ///
    func presentProductTypeBottomSheet(creationType: ProductCreationType) {
        let title: String? = {
            guard creationType == .template else { return nil }
            return NSLocalizedString("Choose a template", comment: "Message title of bottom sheet for selecting a template or manual product")
        }()
        let subtitle = NSLocalizedString("Select a product type",
                                         comment: "Message subtitle of bottom sheet for selecting a product type to create a product")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title, subtitle: subtitle)
        let command = ProductTypeBottomSheetListSelectorCommand(selected: nil) { selectedBottomSheetProductType in
            ServiceLocator.analytics.track(.addProductTypeSelected, withProperties: ["product_type": selectedBottomSheetProductType.productType.rawValue])
            self.navigationController.dismiss(animated: true) {
                switch creationType {
                case .manual:
                    self.presentProductForm(bottomSheetProductType: selectedBottomSheetProductType)
                case .template:
                    self.createAndPresentTemplate(productType: selectedBottomSheetProductType)
                }
            }
        }

        switch creationType {
        case .template:
            command.data = [.simple(isVirtual: false), .simple(isVirtual: true), .variable]
        case .manual:
            command.data = [.simple(isVirtual: false), .simple(isVirtual: true), .variable, .grouped, .affiliate]
        }

        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)

        // `topmostPresentedViewController` is used because another bottom sheet could have been presented before.
        productTypesListPresenter.show(from: navigationController.topmostPresentedViewController,
                                       sourceView: sourceView,
                                       sourceBarButtonItem: sourceBarButtonItem,
                                       arrowDirections: .any)
    }

    /// Creates & Fetches a template product.
    /// If success: Navigates to the product.
    /// If failure: Shows an error notice
    ///
    func createAndPresentTemplate(productType: BottomSheetProductType) {
        guard let template = Self.templateType(from: productType) else {
            DDLogError("⛔️ Product Type: \(productType) not supported as a template.")
            return presentErrorNotice()
        }

        // Loading ViewController while the product is being created
        let loadingTitle = NSLocalizedString("Creating Template Product...", comment: "Loading text while creating a product from a template")
        let viewProperties = InProgressViewProperties(title: loadingTitle, message: "")
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)

        let action = ProductAction.createTemplateProduct(siteID: siteID, template: template) { result in

            // Dismiss the loader
            inProgressViewController.dismiss(animated: true)

            switch result {
            case .success(let product):
                // Transforms the auto-draft product into a new product ready to be used.
                let newProduct = ProductFactory().newProduct(from: product)
                self.presentProduct(newProduct) // We need to strongly capture `self` because no one is retaining `AddProductCoordinator`.

            case .failure(let error):
                // Log error and inform the user
                DDLogError("⛔️ There was an error creating the template product: \(error)")
                self.presentErrorNotice()
            }
        }

        ServiceLocator.stores.dispatch(action)

        // Present loader right after the creation action is dispatched.
        inProgressViewController.modalPresentationStyle = .overCurrentContext
        self.navigationController.tabBarController?.present(inProgressViewController, animated: true, completion: nil)
    }

    /// Presents a new product based on the provided bottom sheet type.
    ///
    func presentProductForm(bottomSheetProductType: BottomSheetProductType) {
        guard let product = ProductFactory().createNewProduct(type: bottomSheetProductType.productType,
                                                              isVirtual: bottomSheetProductType.isVirtual,
                                                              siteID: siteID) else {
            assertionFailure("Unable to create product of type: \(bottomSheetProductType)")
            return
        }
        presentProduct(product)
    }

    /// Presents a product onto the current navigation stack.
    ///
    func presentProduct(_ product: Product) {
        let model = EditableProductModel(product: product)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let currency = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: model.productID),
                                      isLocalID: true),
                           originalStatuses: model.imageStatuses)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: .add,
                                             productImageActionHandler: productImageActionHandler)
        viewModel.onProductCreated = { [weak self] product in
            guard let self else { return }
            self.onProductCreated(product)
            if self.isFirstProduct, let url = URL(string: product.permalink) {
                self.showFirstProductCreatedView(productURL: url)
            }
        }
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       eventLogger: ProductFormEventLogger(),
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currency,
                                                       presentationStyle: .navigationStack)
        // Since the Add Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    /// Converts a `BottomSheetProductType` type to a `ProductsRemote.TemplateType` template type.
    /// Returns `nil` if the `BottomSheetProductType` is not supported or does not exist.
    ///
    static func templateType(from productType: BottomSheetProductType) -> ProductsRemote.TemplateType? {
        switch productType {
        case .simple(let isVirtual):
            if isVirtual {
                return .digital
            } else {
                return .physical
            }
        case .variable:
            return .variable
        case .affiliate:
            return .external
        case .grouped:
            return .grouped
        default:
            return nil
        }
    }

    /// Presents an general error notice using the system notice presenter.
    ///
    func presentErrorNotice() {
        let notice = Notice(title: NSLocalizedString("There was a problem creating the template product.",
                                                     comment: "Title for the error notice when creating a template product"))
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Tracks the selected product creation type.
    ///
    func trackProductCreationType(_ type: ProductCreationType) {
        let analyticsType: WooAnalyticsEvent.ProductsOnboarding.CreationType = {
            switch type {
            case .template:
                return .template
            case .manual:
                return .manual
            }
        }()
        ServiceLocator.analytics.track(event: .ProductsOnboarding.productCreationTypeSelected(type: analyticsType))
    }

    /// Presents the celebratory view for the first created product.
    ///
    func showFirstProductCreatedView(productURL: URL) {
        let viewController = FirstProductCreatedHostingController(productURL: productURL)
        navigationController.present(UINavigationController(rootViewController: viewController), animated: true)
    }
}
