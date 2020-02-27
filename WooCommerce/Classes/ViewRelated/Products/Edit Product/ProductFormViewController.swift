import UIKit
import Yosemite

/// The entry UI for adding/editing a Product.
final class ProductFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var product: Product {
        didSet {
            viewModel = DefaultProductFormTableViewModel(product: product, currency: currency)
            tableViewDataSource = ProductFormTableViewDataSource(viewModel: viewModel,
                                                                 productImageStatuses: productImagesService.productImageStatuses,
                                                                 productImagesProvider: productImagesProvider)
            tableViewDataSource.configureActions(onAddImage: { [weak self] in
                self?.showProductImages()
            })
            tableView.dataSource = tableViewDataSource
            tableView.reloadData()
        }
    }

    private var productUpdater: ProductUpdater {
        return product
    }

    private var viewModel: ProductFormTableViewModel
    private var tableViewDataSource: ProductFormTableViewDataSource

    private let productImagesService: ProductImagesService
    private let productImagesProvider: ProductImagesProvider

    private let currency: String

    init(product: Product, currency: String) {
        self.currency = currency
        self.product = product
        self.viewModel = DefaultProductFormTableViewModel(product: product, currency: currency)
        self.productImagesService = ProductImagesService(siteID: product.siteID,
                                                         product: product)
        self.productImagesProvider = DefaultProductImagesProvider(productImagesService: productImagesService)
        self.tableViewDataSource = ProductFormTableViewDataSource(viewModel: viewModel,
                                                                  productImageStatuses: productImagesService.productImageStatuses,
                                                                  productImagesProvider: productImagesProvider)
        super.init(nibName: nil, bundle: nil)
        tableViewDataSource.configureActions(onAddImage: { [weak self] in
            self?.showProductImages()
        })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureTableView()

        productImagesService.addUpdateObserver(self) { [weak self] (productImageStatuses, error) in
            guard let self = self else {
                return
            }

            if error != nil {
                let title = NSLocalizedString("Cannot upload image", comment: "The title of the alert when there is an error uploading an image")
                let message = NSLocalizedString("Please try again.", comment: "The message of the alert when there is an error uploading an image")
                self.displayErrorAlert(title: title, message: message)
            }

            self.product = self.productUpdater.imagesUpdated(images: productImageStatuses.images)
        }
    }
}

private extension ProductFormViewController {
    func configureNavigationBar() {
        let updateTitle = NSLocalizedString("Update", comment: "Action for updating a Product remotely")
        navigationItem.rightBarButtonItems = [UIBarButtonItem(title: updateTitle, style: .done, target: self, action: #selector(updateProduct))]

        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.editProductsRelease2) {
            navigationItem.rightBarButtonItems?.insert(createMoreOptionsBarButtonItem(), at: 0)
        }
        removeNavigationBackBarButtonText()
    }

    func createMoreOptionsBarButtonItem() -> UIBarButtonItem {
        let moreButton = UIBarButtonItem(image: .moreImage,
                                     style: .plain,
                                     target: self,
                                     action: #selector(presentMoreOptionsActionSheet))
        moreButton.accessibilityLabel = NSLocalizedString("More options", comment: "Accessibility label for the Edit Product More Options action sheet")
        moreButton.accessibilityIdentifier = "edit-product-more-options-button"
        return moreButton
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        registerTableViewCells()

        tableView.dataSource = tableViewDataSource
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        tableView.reloadData()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        viewModel.sections.forEach { section in
            switch section {
            case .primaryFields(let rows):
                rows.forEach { row in
                    row.cellTypes.forEach { cellType in
                        tableView.register(cellType.loadNib(), forCellReuseIdentifier: cellType.reuseIdentifier)
                    }
                }
            default:
                return
            }
        }
    }
}

// MARK: Navigation actions
//
private extension ProductFormViewController {
    @objc func updateProduct() {
        ServiceLocator.analytics.track(.productDetailUpdateButtonTapped)
        let title = NSLocalizedString("Publishing your product...", comment: "Title of the in-progress UI while updating the Product remotely")
        let message = NSLocalizedString("Please wait while we publish this product to your store",
                                        comment: "Message of the in-progress UI while updating the Product remotely")
        let viewProperties = InProgressViewProperties(title: title, message: message)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)

        // Before iOS 13, a modal with transparent background requires certain
        // `modalPresentationStyle` to prevent the view from turning dark after being presented.
        if #available(iOS 13.0, *) {} else {
            inProgressViewController.modalPresentationStyle = .overCurrentContext
        }

        navigationController?.present(inProgressViewController, animated: true, completion: nil)

        let action = ProductAction.updateProduct(product: product) { [weak self] (product, error) in
            guard let product = product, error == nil else {
                let errorDescription = error?.localizedDescription ?? "No error specified"
                DDLogError("⛔️ Error updating Product: \(errorDescription)")
                ServiceLocator.analytics.track(.productDetailUpdateError)
                // Dismisses the in-progress UI then presents the error alert.
                self?.navigationController?.dismiss(animated: true) {
                    self?.displayError(error: error)
                }
                return
            }
            self?.product = product

            ServiceLocator.analytics.track(.productDetailUpdateSuccess)
            // Dismisses the in-progress UI.
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }
        ServiceLocator.stores.dispatch(action)
    }

    func displayError(error: ProductUpdateError?) {
        let title = NSLocalizedString("Cannot update Product", comment: "The title of the alert when there is an error updating the product")

        let message = error?.alertMessage

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

    func shareProduct() {
        guard let url = URL(string: product.permalink) else {
            return
        }

        SharingHelper.shareURL(url: url, title: product.name, from: view, in: self)
    }

    func displayProductSettings() {
        let viewController = ProductSettingsViewController(product: product)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension ProductFormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = viewModel.sections[indexPath.section]
        switch section {
        case .primaryFields(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .images:
                break
            case .name:
                ServiceLocator.analytics.track(.productDetailViewProductNameTapped)
                editProductName()
            case .description:
                ServiceLocator.analytics.track(.productDetailViewProductDescriptionTapped)
                editProductDescription()
            }
        case .settings(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .price:
                ServiceLocator.analytics.track(.productDetailViewPriceSettingsTapped)
                editPriceSettings()
            case .shipping:
                ServiceLocator.analytics.track(.productDetailViewShippingSettingsTapped)
                editShippingSettings()
            case .inventory:
                ServiceLocator.analytics.track(.productDetailViewInventorySettingsTapped)
                editInventorySettings()
            case .briefDescription:
                // TODO-1879: Edit Products M2 analytics
                editBriefDescription()
                break
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = viewModel.sections[section]
        switch section {
        case .settings:
            return Constants.settingsHeaderHeight
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = viewModel.sections[section]
        switch section {
        case .settings:
            let clearView = UIView(frame: .zero)
            clearView.backgroundColor = .clear
            return clearView
        default:
            return nil
        }
    }
}

// MARK: Action - Edit Product Images
//
private extension ProductFormViewController {
    func showProductImages() {
        let imagesViewController = ProductImagesViewController(product: product,
                                                               productImagesService: productImagesService,
                                                               productImagesProvider: productImagesProvider) { [weak self] images in
            self?.onEditProductImagesCompletion(images: images)
        }
        navigationController?.pushViewController(imagesViewController, animated: true)
    }

    func onEditProductImagesCompletion(images: [ProductImage]) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        guard images != product.images else {
            return
        }
        self.product = productUpdater.imagesUpdated(images: images)
    }
}

// MARK: Action - Edit Product Name
//
private extension ProductFormViewController {
    func editProductName() {
        let placeholder = NSLocalizedString("Enter a title...", comment: "The text placeholder for the Text Editor screen")
        let navigationTitle = NSLocalizedString("Title", comment: "The navigation bar title of the Text editor screen.")
        let textViewController = TextViewViewController(text: product.name,
                                                        placeholder: placeholder,
                                                        navigationTitle: navigationTitle
        ) { [weak self] (newProductName) in
            self?.onEditProductNameCompletion(newName: newProductName ?? "")
        }
        textViewController.delegate = self

        navigationController?.pushViewController(textViewController, animated: true)
    }

    func onEditProductNameCompletion(newName: String) {
        defer {
            navigationController?.popViewController(animated: true)
        }

        let hasChangedData = newName != product.name
        ServiceLocator.analytics.track(.productNameDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])

        guard hasChangedData else {
            return
        }
        self.product = productUpdater.nameUpdated(name: newName)
    }
}

extension ProductFormViewController: TextViewViewControllerDelegate {
    func validate(text: String) -> Bool {
        return !text.isEmpty
    }

    func validationErrorMessage() -> String {
        return NSLocalizedString("Please add a title",
                                 comment: "Product title error notice message, when the title is empty")
    }


}

// MARK: Action - Edit Product Parameters
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
        let hasChangedData = newDescription != product.fullDescription
        ServiceLocator.analytics.track(.productDescriptionDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])

        guard hasChangedData else {
            return
        }
        self.product = productUpdater.descriptionUpdated(description: newDescription)
    }
}

// MARK: Action - Edit Product Price Settings
//
private extension ProductFormViewController {
    func editPriceSettings() {
        let priceSettingsViewController = ProductPriceSettingsViewController(product: product) { [weak self]
            (regularPrice, salePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass) in
            self?.onEditPriceSettingsCompletion(regularPrice: regularPrice,
                                                salePrice: salePrice,
                                                dateOnSaleStart: dateOnSaleStart,
                                                dateOnSaleEnd: dateOnSaleEnd,
                                                taxStatus: taxStatus,
                                                taxClass: taxClass)
        }
        navigationController?.pushViewController(priceSettingsViewController, animated: true)
    }

    func onEditPriceSettingsCompletion(regularPrice: String?,
                                       salePrice: String?,
                                       dateOnSaleStart: Date?,
                                       dateOnSaleEnd: Date?,
                                       taxStatus: ProductTaxStatus,
                                       taxClass: TaxClass?) {
        defer {
            navigationController?.popViewController(animated: true)
        }

        let hasChangedData: Bool = {
            regularPrice != product.regularPrice ||
                salePrice != product.salePrice ||
                dateOnSaleStart != product.dateOnSaleStart ||
                dateOnSaleEnd != product.dateOnSaleEnd ||
                taxStatus != product.productTaxStatus ||
                taxClass?.slug != product.taxClass
        }()

        ServiceLocator.analytics.track(.productPriceSettingsDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])
        guard hasChangedData else {
            return
        }

        self.product = productUpdater.priceSettingsUpdated(regularPrice: regularPrice,
                                                           salePrice: salePrice,
                                                           dateOnSaleStart: dateOnSaleStart,
                                                           dateOnSaleEnd: dateOnSaleEnd,
                                                           taxStatus: taxStatus,
                                                           taxClass: taxClass)
    }
}

// MARK: Action - Edit Product Shipping Settings
//
private extension ProductFormViewController {
    func editShippingSettings() {
        let shippingSettingsViewController = ProductShippingSettingsViewController(product: product) { [weak self] (weight, dimensions, shippingClass) in
            self?.onEditShippingSettingsCompletion(weight: weight, dimensions: dimensions, shippingClass: shippingClass)
        }
        navigationController?.pushViewController(shippingSettingsViewController, animated: true)
    }

    func onEditShippingSettingsCompletion(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData: Bool = {
            weight != self.product.weight ||
                dimensions != self.product.dimensions ||
                shippingClass != product.productShippingClass
        }()
        ServiceLocator.analytics.track(.productShippingSettingsDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])

        guard hasChangedData else {
            return
        }
        self.product = productUpdater.shippingSettingsUpdated(weight: weight, dimensions: dimensions, shippingClass: shippingClass)
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
        let originalData = ProductInventoryEditableData(product: product)
        let hasChangedData = originalData != data
        ServiceLocator.analytics.track(.productInventorySettingsDoneButtonTapped, withProperties: ["has_changed_data": hasChangedData])

        guard hasChangedData else {
            return
        }
        self.product = productUpdater.inventorySettingsUpdated(sku: data.sku,
                                                               manageStock: data.manageStock,
                                                               soldIndividually: data.soldIndividually,
                                                               stockQuantity: data.stockQuantity,
                                                               backordersSetting: data.backordersSetting,
                                                               stockStatus: data.stockStatus)
    }
}

// MARK: Action - Edit Product Brief Description (Short Description)
//
private extension ProductFormViewController {
    func editBriefDescription() {
        let editorViewController = EditorFactory().productBriefDescriptionEditor(product: product) { [weak self] content in
            self?.onEditBriefDescriptionCompletion(newBriefDescription: content)
        }
        navigationController?.pushViewController(editorViewController, animated: true)
    }

    func onEditBriefDescriptionCompletion(newBriefDescription: String) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        let hasChangedData = newBriefDescription != product.briefDescription
        // TODO-1879: Edit Products M2 analytics

        guard hasChangedData else {
            return
        }
        self.product = productUpdater.briefDescriptionUpdated(briefDescription: newBriefDescription)
    }
}

// MARK: Action Sheet
//
private extension ProductFormViewController {

    /// More Options Action Sheet
    ///
    @objc func presentMoreOptionsActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addDefaultActionWithTitle(ActionSheetStrings.share) { [weak self] _ in
            self?.shareProduct()
        }

        actionSheet.addDefaultActionWithTitle(ActionSheetStrings.productSettings) { [weak self] _ in
            self?.displayProductSettings()
        }

        actionSheet.addCancelActionWithTitle(ActionSheetStrings.cancel) { _ in
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = view
        popoverController?.sourceRect = view.bounds

        present(actionSheet, animated: true)
    }

    enum ActionSheetStrings {
        static let share = NSLocalizedString("Share", comment: "Button title Share in Edit Product More Options Action Sheet")
        static let productSettings = NSLocalizedString("Product Settings", comment: "Button title Product Settings in Edit Product More Options Action Sheet")
        static let cancel = NSLocalizedString("Cancel", comment: "Button title Cancel in Edit Product More Options Action Sheet")
    }
}

// MARK: Constants
//
private extension ProductFormViewController {
    enum Constants {
        static let settingsHeaderHeight = CGFloat(16)
    }
}
