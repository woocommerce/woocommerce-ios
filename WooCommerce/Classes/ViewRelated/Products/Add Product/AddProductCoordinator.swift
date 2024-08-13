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
            analytics.track(event: .ProductsOnboarding.productListAddProductButtonTapped(horizontalSizeClass: UITraitCollection.current.horizontalSizeClass))
        default:
            break
        }

        analytics.track(event: .ProductCreation.addProductStarted(source: source, storeHasProducts: storeHasProducts))

        if shouldSkipBottomSheet {
            presentProductForm(bottomSheetProductType: .simple(isVirtual: false))
        } else if shouldShowAIActionSheet {
            presentActionSheetWithAI()
        } else {
            presentProductTypeBottomSheet()
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

    /// Presents a bottom sheet for users to choose if what kind of product they want to create.
    ///
    func presentProductTypeBottomSheet() {
        let subtitle = NSLocalizedString("Select a product type",
                                         comment: "Message subtitle of bottom sheet for selecting a product type to create a product")
        let viewProperties = BottomSheetListSelectorViewProperties(subtitle: subtitle)
        let command = ProductTypeBottomSheetListSelectorCommand(
            source: .creationForm,
            subscriptionProductsEligibilityChecker: wooSubscriptionProductsEligibilityChecker
        ) { [weak self] selectedBottomSheetProductType in
            guard let self else { return }
            self.analytics.track(event: .ProductCreation
                .addProductTypeSelected(bottomSheetProductType: selectedBottomSheetProductType))
            self.navigationController.dismiss(animated: true) {
                self.presentProductForm(bottomSheetProductType: selectedBottomSheetProductType)
            }
        }

        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)

        // `topmostPresentedViewController` is used because another bottom sheet could have been presented before.
        productTypesListPresenter.show(from: navigationController.topmostPresentedViewController,
                                       sourceView: sourceView,
                                       sourceBarButtonItem: sourceBarButtonItem,
                                       arrowDirections: .any)
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
                    self?.analytics.track(event: .ProductCreation.addProductTypeSelected(bottomSheetProductType: selectedBottomSheetProductType))
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
