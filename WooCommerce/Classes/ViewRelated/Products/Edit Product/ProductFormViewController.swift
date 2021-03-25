import Photos
import UIKit
import WordPressUI
import Yosemite
import Observables

/// The entry UI for adding/editing a Product.
final class ProductFormViewController<ViewModel: ProductFormViewModelProtocol>: UIViewController, UITableViewDelegate {
    typealias ProductModel = ViewModel.ProductModel

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var moreDetailsContainerView: UIView!

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    private let viewModel: ViewModel
    private let eventLogger: ProductFormEventLoggerProtocol
    private var product: ProductModel {
        viewModel.productModel
    }

    private var password: String? {
        viewModel.password
    }

    private var tableViewModel: ProductFormTableViewModel
    private var tableViewDataSource: ProductFormTableViewDataSource {
        didSet {
            registerTableViewCells()
        }
    }

    private let productImageActionHandler: ProductImageActionHandler
    private let productUIImageLoader: ProductUIImageLoader

    private let currency: String

    private lazy var exitForm: () -> Void = {
        presentationStyle.createExitForm(viewController: self)
    }()

    private let presentationStyle: ProductFormPresentationStyle
    private let navigationRightBarButtonItemsSubject = PublishSubject<[UIBarButtonItem]>()
    private var navigationRightBarButtonItems: Observable<[UIBarButtonItem]> {
        navigationRightBarButtonItemsSubject
    }
    private var cancellableProduct: ObservationToken?
    private var cancellableProductName: ObservationToken?
    private var cancellableUpdateEnabled: ObservationToken?

    init(viewModel: ViewModel,
         eventLogger: ProductFormEventLoggerProtocol,
         productImageActionHandler: ProductImageActionHandler,
         currency: String = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode),
         presentationStyle: ProductFormPresentationStyle) {
        self.viewModel = viewModel
        self.eventLogger = eventLogger
        self.currency = currency
        self.presentationStyle = presentationStyle
        self.productImageActionHandler = productImageActionHandler
        self.productUIImageLoader = DefaultProductUIImageLoader(productImageActionHandler: productImageActionHandler,
                                                                phAssetImageLoaderProvider: { PHImageManager.default() })
        self.tableViewModel = DefaultProductFormTableViewModel(product: viewModel.productModel,
                                                               actionsFactory: viewModel.actionsFactory,
                                                               currency: currency)
        self.tableViewDataSource = ProductFormTableViewDataSource(viewModel: tableViewModel,
                                                                  productImageStatuses: productImageActionHandler.productImageStatuses,
                                                                  productUIImageLoader: productUIImageLoader)
        super.init(nibName: "ProductFormViewController", bundle: nil)
        tableViewDataSource.configureActions(onNameChange: { [weak self] name in
            self?.onEditProductNameCompletion(newName: name ?? "")
        }, onStatusChange: { [weak self] isVisible in
            self?.onEditStatusCompletion(isEnabled: isVisible)
        }, onAddImage: { [weak self] in
            self?.eventLogger.logImageTapped()
            self?.showProductImages()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cancellableProduct?.cancel()
        cancellableProductName?.cancel()
        cancellableUpdateEnabled?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configurePresentationStyle()
        configureNavigationBar()
        configureMainView()
        configureTableView()
        configureMoreDetailsContainerView()

        startListeningToNotifications()
        handleSwipeBackGesture()

        observeProduct()
        observeProductName()
        observeUpdateCTAVisibility()

        productImageActionHandler.addUpdateObserver(self) { [weak self] (productImageStatuses, error) in
            guard let self = self else {
                return
            }

            if error != nil {
                let title = NSLocalizedString("Cannot upload image", comment: "The title of the alert when there is an error uploading an image")
                let message = NSLocalizedString("Please try again.", comment: "The message of the alert when there is an error uploading an image")
                self.displayErrorAlert(title: title, message: message)
            }

            if productImageStatuses.hasPendingUpload {
                self.onImageStatusesUpdated(statuses: productImageStatuses)
            }

            self.viewModel.updateImages(productImageStatuses.images)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    // MARK: - Navigation actions handling

    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.hasUnsavedChanges() == false else {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    // MARK: Product save action handling

    func dismissOrPopViewController() {
        switch self.presentationStyle {
        case .navigationStack:
            self.navigationController?.popViewController(animated: true)
        default:
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc func saveProductAndLogEvent() {
        eventLogger.logUpdateButtonTapped()
        saveProduct()
    }

    @objc func publishProduct() {
        if viewModel.formType == .add {
            ServiceLocator.analytics.track(.addProductPublishTapped, withProperties: ["product_type": product.productType.rawValue])
        }
        saveProduct(status: .publish)
    }

    func saveProductAsDraft() {
        if viewModel.formType == .add {
            ServiceLocator.analytics.track(.addProductSaveAsDraftTapped, withProperties: ["product_type": product.productType.rawValue])
        }
        saveProduct(status: .draft)
    }

    // MARK: Navigation actions

    @objc func closeNavigationBarButtonTapped() {
        guard viewModel.hasUnsavedChanges() == false else {
            presentBackNavigationActionSheet()
            return
        }
        exitForm()
    }

    // MARK: Action Sheet

    /// More Options Action Sheet
    ///
    @objc func presentMoreOptionsActionSheet(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        if viewModel.canShowPublishOption() {
            actionSheet.addDefaultActionWithTitle(Localization.publishTitle) { [weak self] _ in
                self?.publishProduct()
            }
        }

        if viewModel.canSaveAsDraft() {
            actionSheet.addDefaultActionWithTitle(ActionSheetStrings.saveProductAsDraft) { [weak self] _ in
                self?.saveProductAsDraft()
            }
        }

        /// The "View product in store" action will be shown only if the product is published.
        if viewModel.canViewProductInStore() {
            actionSheet.addDefaultActionWithTitle(ActionSheetStrings.viewProduct) { [weak self] _ in
                ServiceLocator.analytics.track(.productDetailViewProductButtonTapped)
                self?.displayWebViewForProductInStore()
            }
        }

        if viewModel.canShareProduct() {
            actionSheet.addDefaultActionWithTitle(ActionSheetStrings.share) { [weak self] _ in
                ServiceLocator.analytics.track(.productDetailShareButtonTapped)
                self?.displayShareProduct()
            }
        }

        if viewModel.canEditProductSettings() {
            actionSheet.addDefaultActionWithTitle(ActionSheetStrings.productSettings) { [weak self] _ in
                ServiceLocator.analytics.track(.productDetailViewSettingsButtonTapped)
                self?.displayProductSettings()
            }
        }

        if viewModel.canDeleteProduct() {
            actionSheet.addDestructiveActionWithTitle(ActionSheetStrings.delete) { [weak self] _ in
                self?.displayDeleteProductAlert()
            }
        }

        actionSheet.addCancelActionWithTitle(ActionSheetStrings.cancel) { _ in
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.barButtonItem = sender

        present(actionSheet, animated: true)
    }


    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = tableViewModel.sections[indexPath.section]
        switch section {
        case .primaryFields(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .description(_, let isEditable):
                guard isEditable else {
                    return
                }
                eventLogger.logDescriptionTapped()
                editProductDescription()
            default:
                break
            }
        case .settings(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .price(_, let isEditable):
                guard isEditable else {
                    return
                }
                eventLogger.logPriceSettingsTapped()
                editPriceSettings()
            case .reviews:
                ServiceLocator.analytics.track(.productDetailViewReviewsTapped)
                showReviews()
            case .downloadableFiles(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewDownloadableFilesTapped)
                showDownloadableFiles()
            case .linkedProducts(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewLinkedProductsTapped)
                editLinkedProducts()
            case .productType(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewProductTypeTapped)
                let cell = tableView.cellForRow(at: indexPath)
                editProductType(cell: cell)
            case .shipping(_, let isEditable):
                guard isEditable else {
                    return
                }
                eventLogger.logShippingSettingsTapped()
                editShippingSettings()
            case .inventory(_, let isEditable):
                guard isEditable else {
                    return
                }
                eventLogger.logInventorySettingsTapped()
                editInventorySettings()
            case .categories(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewCategoriesTapped)
                editCategories()
            case .tags(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewTagsTapped)
                editTags()
            case .shortDescription(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewShortDescriptionTapped)
                editShortDescription()
            case .externalURL(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewExternalProductLinkTapped)
                editExternalLink()
                break
            case .sku(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewSKUTapped)
                editSKU()
                break
            case .groupedProducts(_, let isEditable):
                guard isEditable else {
                    return
                }
                ServiceLocator.analytics.track(.productDetailViewGroupedProductsTapped)
                editGroupedProducts()
                break
            case .variations(let row):
                ServiceLocator.analytics.track(.productDetailViewVariationsTapped)
                guard let originalProduct = viewModel.originalProductModel as? EditableProductModel, row.isActionable else {
                    return
                }
                let variationsViewModel = ProductVariationsViewModel(formType: viewModel.formType)
                let variationsViewController = ProductVariationsViewController(viewModel: variationsViewModel,
                                                                               product: originalProduct.product)
                variationsViewController.onProductUpdate = { [viewModel] updatedProduct in
                    viewModel.updateProductVariations(from: updatedProduct)
                }
                show(variationsViewController, sender: self)
            case .attributes(_, let isEditable):
                guard isEditable else {
                    return
                }
                editVariationAttributes()
                trackEditVariationAttributesRowTapped()
            case .status, .noPriceWarning:
                break
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = tableViewModel.sections[section]
        switch section {
        case .settings:
            return Constants.settingsHeaderHeight
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = tableViewModel.sections[section]
        switch section {
        case .settings:
            let clearView = UIView(frame: .zero)
            clearView.backgroundColor = .listBackground
            return clearView
        default:
            return nil
        }
    }
}

// MARK: - Configuration
//
private extension ProductFormViewController {
    func configureNavigationBar() {
        updateNavigationBar()
        updateBackButtonTitle()
    }

    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureTableView() {
        registerTableViewCells()

        tableView.dataSource = tableViewDataSource
        tableView.delegate = self

        tableView.backgroundColor = .listForeground
        tableView.removeLastCellSeparator()

        // Since the table view is in a container under a stack view, the safe area adjustment should be handled in the container view.
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.reloadData()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        tableViewModel.sections.forEach { section in
            switch section {
            case .primaryFields(let rows):
                rows.forEach { row in
                    row.cellTypes.forEach { cellType in
                        tableView.registerNib(for: cellType)
                    }
                }
            case .settings(let rows):
                rows.forEach { row in
                    row.cellTypes.forEach { cellType in
                        tableView.registerNib(for: cellType)
                    }
                }
            }
        }
    }

    func configurePresentationStyle() {
        switch presentationStyle {
        case .contained(let containerViewController):
            containerViewController.addCloseNavigationBarButton(target: self, action: #selector(closeNavigationBarButtonTapped))
        case .navigationStack:
            break
        }
    }

    func configureMoreDetailsContainerView() {
        let title = NSLocalizedString("Add more details", comment: "Title of the button at the bottom of the product form to add more product details.")
        let viewModel = BottomButtonContainerView.ViewModel(style: .link,
                                                            title: title,
                                                            image: .plusImage) { [weak self] button in
                                                                self?.moreDetailsButtonTapped(button: button)
        }
        let buttonContainerView = BottomButtonContainerView(viewModel: viewModel)

        moreDetailsContainerView.addSubview(buttonContainerView)
        moreDetailsContainerView.pinSubviewToAllEdges(buttonContainerView)
        moreDetailsContainerView.setContentCompressionResistancePriority(.required, for: .vertical)
        moreDetailsContainerView.setContentHuggingPriority(.required, for: .vertical)

        updateMoreDetailsButtonVisibility()
    }
}

// MARK: - Observations & responding to changes
//
private extension ProductFormViewController {
    func observeProduct() {
        cancellableProduct = viewModel.observableProduct.subscribe { [weak self] product in
            self?.onProductUpdated(product: product)
        }
    }

    /// Observe product name changes and re-render the product if the change happened outside this screen.
    /// The "happened outside" condition is needed to not reload the view while the user is typing a new name.
    ///
    func observeProductName() {
        cancellableProductName = viewModel.productName?.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.updateBackButtonTitle()
            if self.view.window == nil { // If window is nil, this screen isn't the active screen.
                self.onProductUpdated(product: self.product)
            }
        }
    }

    func observeUpdateCTAVisibility() {
        cancellableUpdateEnabled = viewModel.isUpdateEnabled.subscribe { [weak self] _ in
            self?.updateNavigationBar()
        }
    }

    func onProductUpdated(product: ProductModel) {
        updateMoreDetailsButtonVisibility()

        tableViewModel = DefaultProductFormTableViewModel(product: product,
                                                          actionsFactory: viewModel.actionsFactory,
                                                          currency: currency)
        tableViewDataSource = ProductFormTableViewDataSource(viewModel: tableViewModel,
                                                             productImageStatuses: productImageActionHandler.productImageStatuses,
                                                             productUIImageLoader: productUIImageLoader)
        tableViewDataSource.configureActions(onNameChange: { [weak self] name in
            self?.onEditProductNameCompletion(newName: name ?? "")
        }, onStatusChange: { [weak self] isEnabled in
            self?.onEditStatusCompletion(isEnabled: isEnabled)
        }, onAddImage: { [weak self] in
            self?.eventLogger.logImageTapped()
            self?.showProductImages()
        })
        tableView.dataSource = tableViewDataSource
        tableView.reloadData()
    }

    func onImageStatusesUpdated(statuses: [ProductImageStatus]) {
        tableViewDataSource = ProductFormTableViewDataSource(viewModel: tableViewModel,
                                                             productImageStatuses: statuses,
                                                             productUIImageLoader: productUIImageLoader)
        tableViewDataSource.configureActions(onNameChange: { [weak self] name in
            self?.onEditProductNameCompletion(newName: name ?? "")
        }, onStatusChange: { [weak self] isEnabled in
            self?.onEditStatusCompletion(isEnabled: isEnabled)
        }, onAddImage: { [weak self] in
            self?.showProductImages()
        })
        tableView.dataSource = tableViewDataSource
        tableView.reloadData()
    }
}

// MARK: More details actions
//
private extension ProductFormViewController {
    func moreDetailsButtonTapped(button: UIButton) {
        let title = NSLocalizedString("Add more details",
                                      comment: "Title of the bottom sheet from the product form to add more product details.")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let actions = viewModel.actionsFactory.bottomSheetActions()
        let dataSource = ProductFormBottomSheetListSelectorCommand(actions: actions) { [weak self] action in
                                                                    self?.dismiss(animated: true) { [weak self] in
                                                                        switch action {
                                                                        case .editInventorySettings:
                                                                            self?.eventLogger.logInventorySettingsTapped()
                                                                            self?.editInventorySettings()
                                                                        case .editShippingSettings:
                                                                            self?.eventLogger.logShippingSettingsTapped()
                                                                            self?.editShippingSettings()
                                                                        case .editCategories:
                                                                            ServiceLocator.analytics.track(.productDetailViewCategoriesTapped)
                                                                            self?.editCategories()
                                                                        case .editTags:
                                                                            ServiceLocator.analytics.track(.productDetailViewTagsTapped)
                                                                            self?.editTags()
                                                                        case .editShortDescription:
                                                                            ServiceLocator.analytics.track(.productDetailViewShortDescriptionTapped)
                                                                            self?.editShortDescription()
                                                                        case .editSKU:
                                                                            ServiceLocator.analytics.track(.productDetailViewSKUTapped)
                                                                            self?.editSKU()
                                                                        case .editLinkedProducts:
                                                                            ServiceLocator.analytics.track(.productDetailViewLinkedProductsTapped)
                                                                            self?.editLinkedProducts()
                                                                        }
                                                                    }
        }
        let listSelectorPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: dataSource)
        listSelectorPresenter.show(from: self, sourceView: button, arrowDirections: .down)
    }

    func updateMoreDetailsButtonVisibility() {
        let moreDetailsActions = viewModel.actionsFactory.bottomSheetActions()
        moreDetailsContainerView.isHidden = moreDetailsActions.isEmpty
    }
}

// MARK: Navigation actions
//
private extension ProductFormViewController {
    func saveProduct(status: ProductStatus? = nil) {
        let productStatus = status ?? product.status
        showSavingProgress(for: productStatus)

        saveImagesAndProductRemotely(status: status)
    }

    func saveImagesAndProductRemotely(status: ProductStatus?) {
        waitUntilAllImagesAreUploaded { [weak self] in
            self?.saveProductRemotely(status: status)
        }
    }

    func waitUntilAllImagesAreUploaded(onCompletion: @escaping () -> Void) {
        let group = DispatchGroup()

        // Waits for all product images to be uploaded before updating the product remotely.
        group.enter()
        // Since `group.leave()` should only be called once to balance `group.enter()`, we track whether there are images pending upload in the image closure.
        var hasNoImagesPendingUpload = false
        let observationToken = productImageActionHandler.addUpdateObserver(self) { [weak self] (productImageStatuses, error) in
            guard hasNoImagesPendingUpload == false else {
                return
            }

            guard let self = self else {
                group.leave()
                return
            }

            guard productImageStatuses.hasPendingUpload == false else {
                return
            }

            hasNoImagesPendingUpload = true

            self.viewModel.updateImages(productImageStatuses.images)
            group.leave()
        }

        group.notify(queue: .main) {
            observationToken.cancel()
            onCompletion()
        }
    }

    func saveProductRemotely(status: ProductStatus?) {
        viewModel.saveProductRemotely(status: status) { [weak self] result in
            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error updating Product: \(error)")

                // Dismisses the in-progress UI then presents the error alert.
                self?.navigationController?.dismiss(animated: true) {
                    self?.displayError(error: error)
                }
            case .success:
                // Dismisses the in-progress UI.
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    func displayError(error: ProductUpdateError?) {
        let title = NSLocalizedString("Cannot update product", comment: "The title of the alert when there is an error updating the product")

        let message = error?.errorDescription

        displayErrorAlert(title: title, message: message)
    }

    func displayErrorAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: NSLocalizedString(
            "OK",
            comment: "Dismiss button on the alert when there is an error updating the product"
        ), style: .cancel, handler: nil)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }

    func displayWebViewForProductInStore() {
        guard let url = URL(string: product.permalink) else {
            return
        }
        WebviewHelper.launch(url, with: self)
    }

    func displayShareProduct() {
        guard let url = URL(string: product.permalink) else {
            return
        }

        SharingHelper.shareURL(url: url, title: product.name, from: view, in: self)
    }

    func displayDeleteProductAlert() {
        let showVariationsText = viewModel is ProductVariationFormViewModel
        if showVariationsText {
            presentVariationConfirmationDeleteAlert { [weak self] isConfirmed in
                guard isConfirmed else {
                    return
                }

                self?.trackVariationRemoveButtonTapped()
                self?.showVariationDeletionProgress()
                self?.deleteProduct()
            }
        } else {
            presentProductConfirmationDeleteAlert { [weak self] isConfirmed in
                guard isConfirmed else {
                    return
                }

                self?.showProductDeletionProgress()
                self?.deleteProduct()
            }
        }
    }

    func deleteProduct() {
        self.viewModel.deleteProductRemotely { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                ServiceLocator.analytics.track(.productDetailProductDeleted)
                // Dismisses the in-progress UI.
                self.navigationController?.dismiss(animated: true, completion: nil)
                // Dismiss or Pop the Product Form
                self.dismissOrPopViewController()
            case .failure(let error):
                DDLogError("⛔️ Error deleting Product: \(error)")

                // Dismisses the in-progress UI then presents the error alert.
                self.navigationController?.dismiss(animated: true) { [weak self] in
                    self?.displayError(error: error)
                }
            }
        }
    }

    func displayProductSettings() {
        guard let product = product as? EditableProductModel else {
            return
        }

        let viewController = ProductSettingsViewController(product: product.product,
                                                           password: password,
                                                           formType: viewModel.formType,
                                                           completion: { [weak self] (productSettings) in
            guard let self = self else {
                return
            }
            self.viewModel.updateProductSettings(productSettings)
        }, onPasswordRetrieved: { [weak self] (originalPassword) in
            self?.viewModel.resetPassword(originalPassword)
        })
        navigationController?.pushViewController(viewController, animated: true)
    }

    func trackVariationRemoveButtonTapped() {
        guard let variation = (product as? EditableProductVariationModel)?.productVariation else {
            return
        }

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Variations.removeVariationButtonTapped(productID: variation.productID,
                                                                                                       variationID: variation.productVariationID))
    }

    func trackEditVariationAttributesRowTapped() {
        guard let variation = (product as? EditableProductVariationModel)?.productVariation else {
            return
        }

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Variations.editVariationAttributeOptionsRowTapped(productID: variation.productID,
                                                                                                                  variationID: variation.productVariationID))
    }
}

// MARK: Navigation Bar Items
//
private extension ProductFormViewController {

    /// Even if the back button don't show any text, we still need a back button title for the menu that is presented by long pressing the back button.
    ///
    func updateBackButtonTitle() {
        navigationItem.backButtonTitle = viewModel.productModel.name.isNotEmpty ? viewModel.productModel.name : Localization.unnamedProduct
    }

    func updateNavigationBar() {
        // Create action buttons based on view model
        let rightBarButtonItems: [UIBarButtonItem] = viewModel.actionButtons.reversed().map { buttonType in
            switch buttonType {
            case .publish:
                return createPublishBarButtonItem()
            case .save:
                return createSaveBarButtonItem()
            case .more:
                return createMoreOptionsBarButtonItem()
            }
        }

        navigationItem.rightBarButtonItems = rightBarButtonItems
        switch presentationStyle {
        case .contained(let containerViewController):
            containerViewController.navigationItem.rightBarButtonItems = rightBarButtonItems
        default:
            break
        }
    }

    func createPublishBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(title: Localization.publishTitle, style: .done, target: self, action: #selector(publishProduct))
    }

    func createSaveBarButtonItem() -> UIBarButtonItem {
        return UIBarButtonItem(title: Localization.saveTitle, style: .done, target: self, action: #selector(saveProductAndLogEvent))
    }

    func createMoreOptionsBarButtonItem() -> UIBarButtonItem {
        let moreButton = UIBarButtonItem(image: .moreImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(presentMoreOptionsActionSheet(_:)))
        moreButton.accessibilityLabel = NSLocalizedString("More options", comment: "Accessibility label for the Edit Product More Options action sheet")
        moreButton.accessibilityIdentifier = "edit-product-more-options-button"
        return moreButton
    }
}

// MARK: - Keyboard management
//
private extension ProductFormViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ProductFormViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

// MARK: - Navigation actions handling
//
private extension ProductFormViewController {
    func presentBackNavigationActionSheet() {
        switch viewModel.formType {
        case .add:
            UIAlertController.presentDiscardNewProductActionSheet(viewController: self,
                                                                  onSaveDraft: { [weak self] in
                                                                    self?.saveProductAsDraft()
                }, onDiscard: { [weak self] in
                    self?.exitForm()
            })
        case .edit:
            UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
                self?.exitForm()
            })
        case .readonly:
            break
        }
    }
}

// MARK: Action - Edit Product Images
//
private extension ProductFormViewController {
    func showProductImages() {
        let imagesViewController = ProductImagesViewController(product: product,
                                                               productImageActionHandler: productImageActionHandler,
                                                               productUIImageLoader: productUIImageLoader) { [weak self] images, hasChangedData in
                                                                self?.onEditProductImagesCompletion(images: images, hasChangedData: hasChangedData)
        }
        navigationController?.pushViewController(imagesViewController, animated: true)
    }

    func onEditProductImagesCompletion(images: [ProductImage], hasChangedData: Bool) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        ServiceLocator.analytics.track(.productImageSettingsDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])
        guard hasChangedData else {
            return
        }
        self.viewModel.updateImages(images)
    }
}

// MARK: Action - Edit Product Name
//
private extension ProductFormViewController {
    func onEditProductNameCompletion(newName: String) {
        viewModel.updateName(newName)

        /// This refresh is used to adapt the size of the cell to the text
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

// MARK: Action - Edit Product Description
//
private extension ProductFormViewController {
    func editProductDescription() {
        let editorViewController = EditorFactory().productDescriptionEditor(product: product) { [weak self] content in
            self?.onEditProductDescriptionCompletion(newDescription: content)
        }
        navigationController?.pushViewController(editorViewController, animated: true)
    }

    func onEditProductDescriptionCompletion(newDescription: String) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = newDescription != product.description
        ServiceLocator.analytics.track(.productDescriptionDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])

        guard hasChangedData else {
            return
        }
        viewModel.updateDescription(newDescription)
    }
}

// MARK: Action - Edit Product Price Settings
//
private extension ProductFormViewController {
    func editPriceSettings() {
        let priceSettingsViewController = ProductPriceSettingsViewController(product: product) { [weak self]
            (regularPrice, salePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass, hasUnsavedChanges) in
            self?.onEditPriceSettingsCompletion(regularPrice: regularPrice,
                                                salePrice: salePrice,
                                                dateOnSaleStart: dateOnSaleStart,
                                                dateOnSaleEnd: dateOnSaleEnd,
                                                taxStatus: taxStatus,
                                                taxClass: taxClass,
                                                hasUnsavedChanges: hasUnsavedChanges)
        }
        navigationController?.pushViewController(priceSettingsViewController, animated: true)
    }

    func onEditPriceSettingsCompletion(regularPrice: String?,
                                       salePrice: String?,
                                       dateOnSaleStart: Date?,
                                       dateOnSaleEnd: Date?,
                                       taxStatus: ProductTaxStatus,
                                       taxClass: TaxClass?,
                                       hasUnsavedChanges: Bool) {
        defer {
            navigationController?.popViewController(animated: true)
        }

        ServiceLocator.analytics.track(.productPriceSettingsDoneButtonTapped, withProperties: ["has_changed_data": hasUnsavedChanges])
        guard hasUnsavedChanges else {
            return
        }

        viewModel.updatePriceSettings(regularPrice: regularPrice,
                                      salePrice: salePrice,
                                      dateOnSaleStart: dateOnSaleStart,
                                      dateOnSaleEnd: dateOnSaleEnd,
                                      taxStatus: taxStatus,
                                      taxClass: taxClass)
    }
}

// MARK: Action - Show Product Reviews Settings
//
private extension ProductFormViewController {
    func showReviews() {
        guard let product = product as? EditableProductModel else {
            return
        }

        let productReviewsViewController = ProductReviewsViewController(product: product.product)
        navigationController?.show(productReviewsViewController, sender: self)
    }
}

// MARK: Action - Edit Product Type Settings
//
private extension ProductFormViewController {
    func editProductType(cell: UITableViewCell?) {
        let title = NSLocalizedString("Change product type",
                                      comment: "Message title of bottom sheet for selecting a product type")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let command = ProductTypeBottomSheetListSelectorCommand(selected: viewModel.productModel.productType) { [weak self] (selectedProductType) in
            self?.dismiss(animated: true, completion: nil)

            guard let originalProductType = self?.product.productType else {
                return
            }

            ServiceLocator.analytics.track(.productTypeChanged, withProperties: [
                "from": originalProductType.rawValue,
                "to": selectedProductType.rawValue
            ])

            self?.presentProductTypeChangeAlert(for: originalProductType, completion: { (change) in
                guard change == true else {
                    return
                }
                self?.viewModel.updateProductType(productType: selectedProductType)
            })
        }
        let productTypesListPresenter = BottomSheetListSelectorPresenter(viewProperties: viewProperties, command: command)
        productTypesListPresenter.show(from: self, sourceView: cell, arrowDirections: .any)
    }
}

// MARK: Action - Edit Product Shipping Settings
//
private extension ProductFormViewController {
    func editShippingSettings() {
        let shippingSettingsViewController = ProductShippingSettingsViewController(product: product) {
            [weak self] (weight, dimensions, shippingClass, shippingClassID, hasUnsavedChanges) in
            self?.onEditShippingSettingsCompletion(weight: weight,
                                                   dimensions: dimensions,
                                                   shippingClass: shippingClass,
                                                   shippingClassID: shippingClassID,
                                                   hasUnsavedChanges: hasUnsavedChanges)
        }
        navigationController?.pushViewController(shippingSettingsViewController, animated: true)
    }

    func onEditShippingSettingsCompletion(weight: String?,
                                          dimensions: ProductDimensions,
                                          shippingClass: String?,
                                          shippingClassID: Int64?,
                                          hasUnsavedChanges: Bool) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        ServiceLocator.analytics.track(.productShippingSettingsDoneButtonTapped, withProperties: ["has_changed_data": hasUnsavedChanges])

        guard hasUnsavedChanges else {
            return
        }
        viewModel.updateShippingSettings(weight: weight, dimensions: dimensions, shippingClass: shippingClass, shippingClassID: shippingClassID)
    }
}

// MARK: Action - Edit Product Inventory Settings
//
private extension ProductFormViewController {
    func editInventorySettings() {
        let inventorySettingsViewController = ProductInventorySettingsViewController(product: product) { [weak self] data in
            self?.onEditInventorySettingsCompletion(data: data)
        }
        navigationController?.pushViewController(inventorySettingsViewController, animated: true)
    }

    func onEditInventorySettingsCompletion(data: ProductInventoryEditableData) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        let originalData = ProductInventoryEditableData(productModel: product)
        let hasChangedData = originalData != data
        //TODO: Add analytics

        guard hasChangedData else {
            return
        }
        viewModel.updateInventorySettings(sku: data.sku,
                                          manageStock: data.manageStock,
                                          soldIndividually: data.soldIndividually,
                                          stockQuantity: data.stockQuantity,
                                          backordersSetting: data.backordersSetting,
                                          stockStatus: data.stockStatus)
    }
}

// MARK: Action - Edit Product Short Description
//
private extension ProductFormViewController {
    func editShortDescription() {
        let editorViewController = EditorFactory().productShortDescriptionEditor(product: product) { [weak self] content in
            self?.onEditShortDescriptionCompletion(newShortDescription: content)
        }
        navigationController?.pushViewController(editorViewController, animated: true)
    }

    func onEditShortDescriptionCompletion(newShortDescription: String) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = newShortDescription != product.shortDescription
        ServiceLocator.analytics.track(.productShortDescriptionDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])

        guard hasChangedData else {
            return
        }
        viewModel.updateShortDescription(newShortDescription)
    }
}

// MARK: Action - Edit Product Categories
//

private extension ProductFormViewController {
    func editCategories() {
        guard let product = product as? EditableProductModel else {
            return
        }

        let categoryListViewController = ProductCategoryListViewController(product: product.product) { [weak self] (categories) in
            self?.onEditCategoriesCompletion(categories: categories)
        }
        show(categoryListViewController, sender: self)
    }

    func onEditCategoriesCompletion(categories: [ProductCategory]) {
        guard let product = product as? EditableProductModel else {
            return
        }

        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = categories.sorted() != product.product.categories.sorted()
        guard hasChangedData else {
            return
        }
        viewModel.updateProductCategories(categories)
    }
}

// MARK: Action - Edit Product Tags
//

private extension ProductFormViewController {
    func editTags() {
        guard let product = product as? EditableProductModel else {
            return
        }

        let tagsViewController = ProductTagsViewController(product: product.product) { [weak self] (tags) in
            self?.onEditTagsCompletion(tags: tags)
        }
        show(tagsViewController, sender: self)
    }

    func onEditTagsCompletion(tags: [ProductTag]) {
        guard let product = product as? EditableProductModel else {
            return
        }

        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = tags.sorted() != product.product.tags.sorted()
        guard hasChangedData else {
            return
        }
        viewModel.updateProductTags(tags)
    }
}

// MARK: Action - Edit Product SKU
//
private extension ProductFormViewController {
    func editSKU() {
        guard let product = product as? EditableProductModel else {
            return
        }

        let viewController = ProductInventorySettingsViewController(product: product, formType: .sku) { [weak self] data in
            self?.onEditSKUCompletion(sku: data.sku)
        }
        show(viewController, sender: self)
    }

    func onEditSKUCompletion(sku: String?) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = sku != product.sku
        ServiceLocator.analytics.track(.productSKUDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])
        guard hasChangedData else {
            return
        }
        viewModel.updateSKU(sku)
    }
}

// MARK: Action - Edit Linked Products
//
private extension ProductFormViewController {
    func editLinkedProducts() {
        let linkedProductsViewController = LinkedProductsViewController(product: product) { [weak self] (upsellIDs, crossSellIDs, hasUnsavedChanges) in
            self?.onEditLinkedProductsCompletion(upsellIDs: upsellIDs, crossSellIDs: crossSellIDs, hasUnsavedChanges: hasUnsavedChanges)
        }
        navigationController?.pushViewController(linkedProductsViewController, animated: true)
    }

    func onEditLinkedProductsCompletion(upsellIDs: [Int64],
                                        crossSellIDs: [Int64],
                                        hasUnsavedChanges: Bool) {
        defer {
            navigationController?.popViewController(animated: true)
        }

        guard hasUnsavedChanges else {
            return
        }
        ServiceLocator.analytics.track(.linkedProducts, withProperties: ["action": "done"])

        viewModel.updateLinkedProducts(upsellIDs: upsellIDs, crossSellIDs: crossSellIDs)
    }
}

// MARK: Action - Edit Grouped Products (Grouped Products Only)
//
private extension ProductFormViewController {
    func editGroupedProducts() {
        guard let product = product as? EditableProductModel else {
            return
        }

        let viewConfiguration = LinkedProductsListSelectorViewController.ViewConfiguration(title: Localization.groupedProductsViewTitle,
                                                                                           trackingContext: "grouped_products")

        let viewController = LinkedProductsListSelectorViewController(product: product.product,
                                                                      linkedProductIDs: product.product.groupedProducts,
                                                                      viewConfiguration: viewConfiguration) { [weak self] groupedProductIDs in
            self?.onEditGroupedProductsCompletion(groupedProductIDs: groupedProductIDs)
        }
        show(viewController, sender: self)
    }

    func onEditGroupedProductsCompletion(groupedProductIDs: [Int64]) {
        guard let product = product as? EditableProductModel else {
            return
        }

        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = groupedProductIDs != product.product.groupedProducts
        guard hasChangedData else {
            return
        }
        viewModel.updateGroupedProductIDs(groupedProductIDs)
    }
}

// MARK: Action - Edit Product External Link
//
private extension ProductFormViewController {
    func editExternalLink() {
        guard let product = product as? EditableProductModel else {
            return
        }

        let viewController = ProductExternalLinkViewController(product: product.product) { [weak self] externalURL, buttonText in
            self?.onEditExternalLinkCompletion(externalURL: externalURL, buttonText: buttonText)
        }
        show(viewController, sender: self)
    }

    func onEditExternalLinkCompletion(externalURL: String?, buttonText: String) {
        guard let product = product as? EditableProductModel else {
            return
        }

        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = externalURL != product.product.externalURL || buttonText != product.product.buttonText
        guard hasChangedData else {
            return
        }
        viewModel.updateExternalLink(externalURL: externalURL, buttonText: buttonText)
    }
}

// MARK: Action - Edit Status (Enabled/Disabled)
//
private extension ProductFormViewController {
    func onEditStatusCompletion(isEnabled: Bool) {
        viewModel.updateStatus(isEnabled)
    }
}

// MARK: Action - Edit Product Downloads
//
private extension ProductFormViewController {
    func showDownloadableFiles() {
        guard let product = product as? EditableProductModel, product.downloadable  else {
            return
        }

        let downloadFileListViewController = ProductDownloadListViewController(product: product) { [weak self] (data, hasUnsavedChanges) in
            self?.onAddEditDownloadsCompletion(data: data, hasUnsavedChanges: hasUnsavedChanges)
        }
        navigationController?.pushViewController(downloadFileListViewController, animated: true)
    }

    func onAddEditDownloadsCompletion(data: ProductDownloadsEditableData,
                                      hasUnsavedChanges: Bool) {
        defer {
            navigationController?.popViewController(animated: true)
        }

        guard hasUnsavedChanges else {
            return
        }
        viewModel.updateDownloadableFiles(downloadableFiles: data.downloadableFiles, downloadLimit: data.downloadLimit, downloadExpiry: data.downloadExpiry)
    }
}

// MARK: Action - Edit Product Variation Attributes
//
private extension ProductFormViewController {
    func editVariationAttributes() {
        guard let productVariationModel = product as? EditableProductVariationModel else {
            return
        }

        let attributePickerViewController = AttributePickerViewController(variationModel: productVariationModel) { [weak self] (attributes) in
            self?.onEditVariationAttributesCompletion(attributes: attributes)
        }
        show(attributePickerViewController, sender: self)
    }

    func onEditVariationAttributesCompletion(attributes: [ProductVariationAttribute]) {
        guard let productVariation = product as? EditableProductVariationModel else {
            return
        }

        defer {
            navigationController?.popViewController(animated: true)
        }

        let hasChangedData = attributes != productVariation.productVariation.attributes
        guard hasChangedData else {
            return
        }
        viewModel.updateVariationAttributes(attributes)
    }
}

// MARK: Constants
//
private enum Localization {
    static let publishTitle = NSLocalizedString("Publish", comment: "Action for creating a new product remotely with a published status")
    static let saveTitle = NSLocalizedString("Save", comment: "Action for saving a Product remotely")
    static let groupedProductsViewTitle = NSLocalizedString("Grouped Products",
                                                            comment: "Navigation bar title for editing linked products for a grouped product")
    static let unnamedProduct = NSLocalizedString("Unnamed product",
                                                  comment: "Back button title when the product doesn't have a name")
}

private enum ActionSheetStrings {
    static let saveProductAsDraft = NSLocalizedString("Save as draft",
                                                      comment: "Button title to save a product as draft in Product More Options Action Sheet")
    static let viewProduct = NSLocalizedString("View Product in Store",
                                               comment: "Button title View product in store in Edit Product More Options Action Sheet")
    static let share = NSLocalizedString("Share", comment: "Button title Share in Edit Product More Options Action Sheet")
    static let delete = NSLocalizedString("Delete", comment: "Button title Delete in Edit Product More Options Action Sheet")
    static let productSettings = NSLocalizedString("Product Settings", comment: "Button title Product Settings in Edit Product More Options Action Sheet")
    static let cancel = NSLocalizedString("Cancel", comment: "Button title Cancel in Edit Product More Options Action Sheet")
}

private enum Constants {
    static let settingsHeaderHeight = CGFloat(16)
}
