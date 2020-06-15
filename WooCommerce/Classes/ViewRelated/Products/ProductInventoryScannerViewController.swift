import UIKit
import WordPressUI
import Yosemite

struct ScannedProductsBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = ProductSKUScannerResult
    typealias Cell = ProductDetailsTableViewCell

    let data: [ProductSKUScannerResult]

    let selected: ProductSKUScannerResult? = nil

    private let imageService: ImageService
    private let onSelection: (ProductSKUScannerResult) -> Void

    init(results: [ProductSKUScannerResult],
         imageService: ImageService = ServiceLocator.imageService,
         onSelection: @escaping (ProductSKUScannerResult) -> Void) {
        self.onSelection = onSelection
        self.imageService = imageService
        self.data = results
    }

    func configureCell(cell: ProductDetailsTableViewCell, model: ProductSKUScannerResult) {
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator

        // TODO-jc: stock quantity tracking
        switch model {
        case .matched(let product):
            cell.configureForInventoryScannerResult(product: product, updatedQuantity: product.stockQuantity, imageService: imageService)
        default:
            break
            //            let vm = ProductDetailsCellViewModel(
            //            cell.configure(item: <#T##ProductDetailsCellViewModel#>, imageService: <#T##ImageService#>)
        }
    }

    func handleSelectedChange(selected: ProductSKUScannerResult) {
        onSelection(selected)
    }

    func isSelected(model: ProductSKUScannerResult) -> Bool {
        return model == selected
    }
}

enum ProductSKUScannerResult {
    case matched(product: Product)
    case noMatch(sku: String)
}

extension ProductSKUScannerResult: Equatable {
    static func ==(lhs: ProductSKUScannerResult, rhs: ProductSKUScannerResult) -> Bool {
        switch (lhs, rhs) {
        case (let .matched(product1), let .matched(product2)):
            return product1 == product2
        case (let .noMatch(sku1), let .noMatch(sku2)):
            return sku1 == sku2
        default:
            return false
        }
    }
}

final class ProductInventoryScannerViewController: UIViewController {

    private lazy var barcodeScannerChildViewController : BarcodeScannerViewController = {
        return BarcodeScannerViewController { [weak self] (barcodes, error) in
            guard let barcode = barcodes.first else {
                return
            }
            self?.searchProductBySKU(barcode: barcode)
        }
    }()

    private var results: [ProductSKUScannerResult] = []

    private var bottomSheetViewController: BottomSheetViewController?
    private var listSelectorViewController: BottomSheetListSelectorViewController<ScannedProductsBottomSheetListSelectorCommand, ProductSKUScannerResult, ProductDetailsTableViewCell>?

    private lazy var statusLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var throttler: Throttler = Throttler(seconds: 1)

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground
        configureNavigation()
        configureBarcodeScannerChildViewController()
        configureStatusLabel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bottomSheetViewController?.show(from: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO-jc: remove. this is just for testing
        searchProductBySKU(barcode: "9789863210887")
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Dismisses the bottom sheet if it is presented.
        bottomSheetViewController?.dismiss(animated: true, completion: nil)

        super.viewWillDisappear(animated)
    }
}

// MARK: Search
//
private extension ProductInventoryScannerViewController {
    func searchProductBySKU(barcode: String) {
        DispatchQueue.main.async {
            self.statusLabel.applyStyle(for: .refunded)
            self.statusLabel.text = NSLocalizedString("Searching for product by the SKU...", comment: "")
            self.showStatusLabel()

            let action = ProductAction.searchProductBySKU(siteID: self.siteID, sku: barcode) { [weak self] result in
                guard let self = self else {
                    return
                }
                switch result {
                case .success(let product):
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    self.statusLabel.applyStyle(for: .processing)
                    self.statusLabel.text = NSLocalizedString("Product found!", comment: "")
                    self.showStatusLabel()

                    self.updateResults(scannedProduct: product)
                case .failure(let error):
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)

                    self.statusLabel.applyStyle(for: .failed)
                    self.statusLabel.text = NSLocalizedString("Product not found", comment: "")
                    self.showStatusLabel()
                    print("No product matched: \(error)")
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
    }

    func updateResults(scannedProduct: Product) {
        results.append(.matched(product: scannedProduct))
        presentSearchResults()
    }

    func presentSearchResults() {
        // TODO-jc: singular vs. plural
        let title = NSLocalizedString("Scanned products",
                                      comment: "Title of the bottom sheet that shows a list of scanned products via the barcode scanner.")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let command = ScannedProductsBottomSheetListSelectorCommand(results: results) { [weak self] result in
            self?.dismiss(animated: true, completion: { [weak self] in
                switch result {
                case .matched(let product):
                    self?.editInventorySettings(for: product)
                case .noMatch(let sku):
                    print("TODO: \(sku)")
                }
            })
        }

        if let listSelectorViewController = listSelectorViewController {
            listSelectorViewController.update(command: command)
            bottomSheetViewController?.view.layoutIfNeeded()
            return
        }

        let listSelectorViewController = BottomSheetListSelectorViewController(viewProperties: viewProperties,
                                                                               command: command) { [weak self] selectedSortOrder in
                                                                                self?.dismiss(animated: true, completion: nil)
        }
        self.listSelectorViewController = listSelectorViewController
        let bottomSheet = BottomSheetViewController(childViewController: listSelectorViewController)
        self.bottomSheetViewController = bottomSheet
        bottomSheet.show(from: self)
    }
}

// MARK: Navigation
//
private extension ProductInventoryScannerViewController {
    @objc func doneButtonTapped() {
        // TODO-jc
    }

    func editInventorySettings(for product: Product) {
        let inventorySettingsViewController = ProductInventorySettingsViewController(product: product) { [weak self] data in
            self?.updateProductInventorySettings(product, inventoryData: data)
        }
        navigationController?.pushViewController(inventorySettingsViewController, animated: true)
    }

    func updateProductInventorySettings(_ product: Product, inventoryData: ProductInventoryEditableData) {
        // TODO-jc: analytics
//        ServiceLocator.analytics.track(.productDetailUpdateButtonTapped)
        let title = NSLocalizedString("Updating inventory", comment: "Title of the in-progress UI while updating the Product inventory settings remotely")
        let message = NSLocalizedString("Please wait while we update inventory for your products",
                                        comment: "Message of the in-progress UI while updating the Product inventory settings remotely")
        let viewProperties = InProgressViewProperties(title: title, message: message)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)

        // Before iOS 13, a modal with transparent background requires certain
        // `modalPresentationStyle` to prevent the view from turning dark after being presented.
        if #available(iOS 13.0, *) {} else {
            inProgressViewController.modalPresentationStyle = .overCurrentContext
        }

        navigationController?.present(inProgressViewController, animated: true, completion: nil)

        let productWithUpdatedInventory = product.inventorySettingsUpdated(sku: inventoryData.sku,
                                                                           manageStock: inventoryData.manageStock,
                                                                           soldIndividually: inventoryData.soldIndividually,
                                                                           stockQuantity: inventoryData.stockQuantity,
                                                                           backordersSetting: inventoryData.backordersSetting,
                                                                           stockStatus: inventoryData.stockStatus)
        let updateProductAction = ProductAction.updateProduct(product: productWithUpdatedInventory) { [weak self] updateResult in
            guard let self = self else {
                return
            }

            switch updateResult {
            case .success(let product):
                // TODO-jc: analytics
                print("Updated \(product.name)!")
//                ServiceLocator.analytics.track(.productDetailUpdateSuccess)
            case .failure(let error):
                let errorDescription = error.localizedDescription
                DDLogError("⛔️ Error updating Product: \(errorDescription)")
                // TODO-jc: display error
                // TODO-jc: analytics
//                ServiceLocator.analytics.track(.productDetailUpdateError)
                // Dismisses the in-progress UI then presents the error alert.
            }
            self.navigationController?.popToViewController(self, animated: true)
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
        ServiceLocator.stores.dispatch(updateProductAction)
    }
}

private extension ProductInventoryScannerViewController {
    func configureNavigation() {
        title = NSLocalizedString("Update inventory", comment: "Navigation bar title on the barcode scanner screen.")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
    }

    func configureBarcodeScannerChildViewController() {
        let contentView = barcodeScannerChildViewController.view!
        addChild(barcodeScannerChildViewController)
        view.addSubview(contentView)
        barcodeScannerChildViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)
    }

    func configureStatusLabel() {
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            statusLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20)
        ])

        hideStatusLabel()
    }
}

// MARK: Status UI
//
private extension ProductInventoryScannerViewController {
    func showStatusLabel() {
        statusLabel.isHidden = false
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.hideStatusLabel()
        }
    }

    func hideStatusLabel() {
        statusLabel.isHidden = true
    }
}
