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
        /// Initiated from the store onboarding card in the dashboard.
        case storeOnboarding
        /// Initiated from the product description AI announcement modal in the dashboard.
        case productDescriptionAIAnnouncementModal
        /// Initiated from the campaign creation entry point when there is no product in the store.
        case blazeCampaignCreation
    }

    /// Source view that initiates product creation for the action sheet to point to.
    enum SourceView {
        case barButtonItem(UIBarButtonItem)
        case view(UIView)
    }

    let navigationController: UINavigationController

    private let siteID: Int64
    private let source: Source
    private let sourceBarButtonItem: UIBarButtonItem?
    private let sourceView: UIView?
    private let productImageUploader: ProductImageUploaderProtocol
    private let storage: StorageManagerType
    private let isFirstProduct: Bool
    private let analytics: Analytics
    private let navigateToProductForm: ((UIViewController) -> Void)?
    private let onDeleteCompletion: () -> Void

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

    private var storeHasProducts: Bool {
        let objects = productsResultsController.fetchedObjects
        return objects.contains(where: { $0.isSampleItem == false })
    }

    private var addProductWithAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol
    private var addProductWithAIBottomSheetPresenter: BottomSheetPresenter?

    private lazy var productCreationAISurveyPresenter: BottomSheetPresenter = {
        BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.prefersGrabberVisible = false
            sheet.detents = [.medium()]
        })
    }()

    private let wooSubscriptionProductsEligibilityChecker: WooSubscriptionProductsEligibilityCheckerProtocol

    /// - Parameters:
    ///   - navigateToProductForm: Optional custom navigation when showing the product form for the new product.
    init(siteID: Int64,
         source: Source,
         sourceView: SourceView?,
         sourceNavigationController: UINavigationController,
         storage: StorageManagerType = ServiceLocator.storageManager,
         addProductWithAIEligibilityChecker: ProductCreationAIEligibilityCheckerProtocol = ProductCreationAIEligibilityChecker(),
         productImageUploader: ProductImageUploaderProtocol = ServiceLocator.productImageUploader,
         analytics: Analytics = ServiceLocator.analytics,
         isFirstProduct: Bool,
         navigateToProductForm: ((UIViewController) -> Void)? = nil,
         onDeleteCompletion: @escaping () -> Void = {}) {
        self.siteID = siteID
        self.source = source
        switch sourceView {
            case let .barButtonItem(barButtonItem):
                self.sourceBarButtonItem = barButtonItem
                self.sourceView = nil
            case let .view(view):
                self.sourceBarButtonItem = nil
                self.sourceView = view
            case .none:
                self.sourceBarButtonItem = nil
                self.sourceView = nil
        }
        self.navigationController = sourceNavigationController
        self.productImageUploader = productImageUploader
        self.storage = storage
        self.addProductWithAIEligibilityChecker = addProductWithAIEligibilityChecker
        self.wooSubscriptionProductsEligibilityChecker = WooSubscriptionProductsEligibilityChecker(siteID: siteID, storage: storage)
        self.analytics = analytics
        self.isFirstProduct = isFirstProduct
        self.navigateToProductForm = navigateToProductForm
        self.onDeleteCompletion = onDeleteCompletion
    }

    func start() {
        switch source {
        case .productsTab:
            analytics.track(event: .ProductsOnboarding
                .productListAddProductButtonTapped(templateEligible: isTemplateOptionsEligible,
                                                   horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
        default:
            break
        }

        analytics.track(event: .ProductCreation.addProductStarted(source: source,
                                                                                 storeHasProducts: storeHasProducts))

        if shouldSkipBottomSheet {
            presentProductForm(bottomSheetProductType: .simple(isVirtual: false))
        } else if shouldShowAIActionSheet {
            presentActionSheetWithAI()
        } else if shouldPresentProductCreationBottomSheet {
            presentProductCreationTypeBottomSheet()
        } else {
            presentProductTypeBottomSheet(creationType: .manual)
        }
    }
}

// MARK: Navigation
private extension AddProductCoordinator {

    /// Whether the action sheet with the option for product creation with AI should be presented.
    ///
    var shouldShowAIActionSheet: Bool {
        addProductWithAIEligibilityChecker.isEligible
    }

    /// Defines if the product creation bottom sheet should be presented.
    /// Currently returns `true` when the store is eligible for displaying template options.
    ///
    var shouldPresentProductCreationBottomSheet: Bool {
        isTemplateOptionsEligible
    }

    /// Defines if it should skip the bottom sheet before the product form is shown.
    /// Currently returns `true` when the source is product description AI announcement modal.
    ///
    var shouldSkipBottomSheet: Bool {
        source == .productDescriptionAIAnnouncementModal
    }

    /// Returns `true` when there are existing products.
    ///
    var shouldShowGroupedProductType: Bool {
        storeHasProducts
    }

    /// Returns `true` when the number of non-sample products is fewer than 3.
    ///
    var isTemplateOptionsEligible: Bool {
        false // Template data is no longer available from remote: https://github.com/woocommerce/woocommerce-ios/issues/12338
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
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm(isForTemplates: creationType == .template),
            subscriptionProductsEligibilityChecker: wooSubscriptionProductsEligibilityChecker
        ) { [weak self] selectedBottomSheetProductType in
            guard let self else { return }
            self.analytics.track(event: .ProductCreation
                .addProductTypeSelected(bottomSheetProductType: selectedBottomSheetProductType,
                                        creationType: creationType))
            self.navigationController.dismiss(animated: true) {
                switch creationType {
                case .manual:
                    self.presentProductForm(bottomSheetProductType: selectedBottomSheetProductType)
                case .template:
                    self.createAndPresentTemplate(productType: selectedBottomSheetProductType)
                }
            }
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

    /// Presents an action sheet with the option to start product creation with AI
    ///
    func presentActionSheetWithAI() {
        let isEligibleForWooSubscriptionProducts = wooSubscriptionProductsEligibilityChecker.isSiteEligible()
        let productTypes: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            isEligibleForWooSubscriptionProducts ? .subscription : nil,
            .variable,
            isEligibleForWooSubscriptionProducts ? .variableSubscription : nil,
            .grouped,
            .affiliate].compactMap { $0 }

        let controller = AddProductWithAIActionSheetHostingController(
            productTypes: productTypes,
            onAIOption: { [weak self] in
                self?.addProductWithAIBottomSheetPresenter?.dismiss {
                    self?.analytics.track(event: .ProductCreationAI.entryPointTapped())
                    self?.addProductWithAIBottomSheetPresenter = nil
                    self?.startProductCreationWithAI()
                }
            },
            onProductTypeOption: { [weak self] selectedBottomSheetProductType in
                self?.addProductWithAIBottomSheetPresenter?.dismiss {
                    self?.analytics.track(event: .ProductCreation
                        .addProductTypeSelected(bottomSheetProductType: selectedBottomSheetProductType,
                                                creationType: .manual))

                    self?.addProductWithAIBottomSheetPresenter = nil
                    self?.presentProductForm(bottomSheetProductType: selectedBottomSheetProductType)
                }
            }
        )

        addProductWithAIBottomSheetPresenter = buildBottomSheetPresenter()
        addProductWithAIBottomSheetPresenter?.present(controller, from: navigationController)
        analytics.track(event: .ProductCreationAI.entryPointDisplayed())
    }

    func startProductCreationWithAI() {
        let viewController = AddProductWithAIContainerHostingController(viewModel: .init(siteID: siteID,
                                                                                         source: source,
                                                                                         onCancel: { [weak self] in
            self?.navigationController.dismiss(animated: true)
        },
                                                                                         onCompletion: { [weak self] product in
            self?.onProductCreated(product)
            self?.navigationController.dismiss(animated: true) {
                self?.presentProduct(product, formType: .edit, isAIContent: true)
                self?.presentProductCreationAIFeedbackIfApplicable()
            }
        }))
        navigationController.present(UINavigationController(rootViewController: viewController), animated: true)
    }

    /// Presents a product onto the current navigation stack.
    ///
    func presentProduct(_ product: Product, formType: ProductFormType = .add, isAIContent: Bool = false) {
        let model = EditableProductModel(product: product)
        let currencyCode = ServiceLocator.currencySettings.currencyCode
        let currency = ServiceLocator.currencySettings.symbol(from: currencyCode)
        let productImageActionHandler = productImageUploader
            .actionHandler(key: .init(siteID: product.siteID,
                                      productOrVariationID: .product(id: model.productID),
                                      isLocalID: true),
                           originalStatuses: model.imageStatuses)
        let viewModel = ProductFormViewModel(product: model,
                                             formType: formType,
                                             productImageActionHandler: productImageActionHandler)
        viewModel.onProductCreated = { [weak self] product in
            guard let self else { return }
            self.onProductCreated(product)
            if self.isFirstProduct, let url = URL(string: product.permalink) {
                self.showFirstProductCreatedView(productURL: url,
                                                 productName: product.name,
                                                 productDescription: product.fullDescription ?? product.shortDescription ?? "",
                                                 showShareProductButton: viewModel.canShareProduct())
            }
        }
        let viewController = ProductFormViewController(viewModel: viewModel,
                                                       isAIContent: isAIContent,
                                                       eventLogger: ProductFormEventLogger(),
                                                       productImageActionHandler: productImageActionHandler,
                                                       currency: currency,
                                                       presentationStyle: .navigationStack,
                                                       onDeleteCompletion: onDeleteCompletion)
        // Since the Add Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
        viewController.hidesBottomBarWhenPushed = true
        if let navigateToProductForm {
            navigateToProductForm(viewController)
        } else {
            navigationController.pushViewController(viewController, animated: true)
        }
    }

    /// Presents AI Product Creation survey
    ///
    func presentProductCreationAIFeedbackIfApplicable() {
        let useCase = ProductCreationAISurveyUseCase()

        guard useCase.shouldShowProductCreationAISurvey() else {
            return
        }

        let controller = ProductCreationAISurveyConfirmationHostingController(viewModel: .init(onStart: { [weak self] in
            guard let self else { return }

            self.productCreationAISurveyPresenter.dismiss(onDismiss: { [weak self] in
                let survey = SurveyCoordinatingController(survey: .productCreationAI)
                self?.navigationController.present(survey, animated: true, completion: nil)
                useCase.didStartProductCreationAISurvey()
            })
        }, onSkip: { [weak self] in
            self?.productCreationAISurveyPresenter.dismiss()
        }))

        productCreationAISurveyPresenter.present(controller, from: navigationController)
        useCase.didSuggestProductCreationAISurvey()
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
        analytics.track(event: .ProductsOnboarding.productCreationTypeSelected(type: analyticsType))
    }

    /// Presents the celebratory view for the first created product.
    ///
    func showFirstProductCreatedView(productURL: URL,
                                     productName: String,
                                     productDescription: String,
                                     showShareProductButton: Bool) {
        let viewController = FirstProductCreatedHostingController(siteID: siteID,
                                                                  productURL: productURL,
                                                                  productName: productName,
                                                                  productDescription: productDescription,
                                                                  showShareProductButton: showShareProductButton)
        navigationController.present(UINavigationController(rootViewController: viewController), animated: true)
    }

    func buildBottomSheetPresenter() -> BottomSheetPresenter {
        BottomSheetPresenter(configure: { bottomSheet in
            var sheet = bottomSheet
            sheet.prefersEdgeAttachedInCompactHeight = true

            // Sets detents for the sheet.
            // Skips large detent if the device is iPad.
            let traitCollection = UIScreen.main.traitCollection
            let isIPad = traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
            if isIPad {
                sheet.detents = [.medium()]
            } else {
                sheet.detents = [.large(), .medium()]
            }
            sheet.prefersGrabberVisible = !isIPad
        })
    }
}
