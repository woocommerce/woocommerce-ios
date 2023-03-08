import Combine
import UIKit
import WordPressUI
import Yosemite

final class ProductInventoryScannerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController = BarcodeScannerViewController(instructionText: Localization.instructionText)

    private var results: [ProductSKUScannerResult] = []

    private var listSelectorViewController: BottomSheetListSelectorViewController
    <ScannedProductsBottomSheetListSelectorCommand, ProductSKUScannerResult, ProductsTabProductTableViewCell>?

    private lazy var statusLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let viewModel: ProductInventoryScannerViewModel

    private var cancellables: Set<AnyCancellable> = []

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        viewModel = ProductInventoryScannerViewModel(siteID: siteID, stores: stores)
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

        if let listSelectorViewController, listSelectorViewController.isBeingPresented == false {
            configureBottomSheetPresentation(for: listSelectorViewController)
            present(listSelectorViewController, animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO-jc: remove. this is just for testing
        searchProductBySKU(barcode: "9789863210887")
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Dismisses the bottom sheet if it is presented.
        if let listSelectorViewController {
            listSelectorViewController.dismiss(animated: true)
        }

        super.viewWillDisappear(animated)
    }
}

// MARK: Search
//
private extension ProductInventoryScannerViewController {
    func searchProductBySKU(barcode: String) {
        DispatchQueue.main.async {
            self.statusLabel.applyStyle(for: .refunded)
            self.statusLabel.text = NSLocalizedString("Scanning barcode", comment: "")
            self.showStatusLabel()

            let action = ProductAction.findProductBySKU(siteID: self.siteID, sku: barcode) { [weak self] result in
                guard let self = self else {
                    return
                }
                switch result {
                case .success(let product):
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    self.statusLabel.applyStyle(for: .processing)
                    self.statusLabel.text = NSLocalizedString("Product Found!", comment: "")
                    self.showStatusLabel()

                    let scannedProduct = EditableProductModel(product: product)
                    self.updateResults(result: .matched(product: scannedProduct))
                case .failure(let error):
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)

                    self.statusLabel.applyStyle(for: .failed)
                    self.statusLabel.text = NSLocalizedString("Product not found", comment: "")
                    self.showStatusLabel()
                    print("No product matched: \(error)")

                    self.updateResults(result: .noMatch(sku: barcode))
                }
            }
            ServiceLocator.stores.dispatch(action)
        }
    }

    func updateResults(result: ProductSKUScannerResult) {
        if results.contains(result) == false {
            results.append(result)
        }
        presentSearchResults()
    }

    func presentSearchResults() {
        // TODO-JC: Singular or plural
        let title = NSLocalizedString("Scanned products",
                                      comment: "Title of the bottom sheet that shows a list of scanned products via the barcode scanner.")
        let viewProperties = BottomSheetListSelectorViewProperties(subtitle: title)
        let command = ScannedProductsBottomSheetListSelectorCommand(results: results) { [weak self] result in
            self?.dismiss(animated: true) { [weak self] in
                switch result {
                case .matched(let product):
                    self?.editInventorySettings(for: product)
                case .noMatch(let sku):
                    // TODO-JC: navigate to let the user select a product for the SKU
                    print("TODO: \(sku)")
                }
            })
        }

        if let listSelectorViewController = listSelectorViewController {
            listSelectorViewController.update(command: command)
            return
        }

        let listSelectorViewController = BottomSheetListSelectorViewController(viewProperties: viewProperties,
                                                                               command: command) { [weak self] selectedSortOrder in
                                                                                self?.dismiss(animated: true, completion: nil)
        }
        self.listSelectorViewController = listSelectorViewController

        configureBottomSheetPresentation(for: listSelectorViewController)
        listSelectorViewController.isModalInPresentation = true
        present(listSelectorViewController, animated: true)
    }
}

// MARK: Navigation
//
private extension ProductInventoryScannerViewController {
    @objc func doneButtonTapped() {
        // TODO-jc
    }

    func editInventorySettings(for product: ProductFormDataModel) {
        let inventorySettingsViewController = ProductInventorySettingsViewController(product: product) { [weak self] data in
            self?.updateProductInventorySettings(product, inventoryData: data)
        }
        navigationController?.pushViewController(inventorySettingsViewController, animated: true)
    }

    func updateProductInventorySettings(_ product: ProductFormDataModel, inventoryData: ProductInventoryEditableData) {
        // TODO-jc: analytics
//        ServiceLocator.analytics.track(.productDetailUpdateButtonTapped)
        let viewProperties = InProgressViewProperties(title: Localization.productInventoryUpdateInProgressTitle,
                                                      message: Localization.productInventoryUpdateInProgressMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext

        navigationController?.present(inProgressViewController, animated: true, completion: nil)

        // TODO-jc: view model
//        let productWithUpdatedInventory = product
//
//
//            .inventorySettingsUpdated(sku: inventoryData.sku,
//                                                                           manageStock: inventoryData.manageStock,
//                                                                           soldIndividually: inventoryData.soldIndividually,
//                                                                           stockQuantity: inventoryData.stockQuantity,
//                                                                           backordersSetting: inventoryData.backordersSetting,
//                                                                           stockStatus: inventoryData.stockStatus)
//        let updateProductAction = ProductAction.updateProduct(product: productWithUpdatedInventory) { [weak self] updateResult in
//            guard let self = self else {
//                return
//            }
//
//            switch updateResult {
//            case .success(let product):
//                // TODO-jc: analytics
//                print("Updated \(product.name)!")
////                ServiceLocator.analytics.track(.productDetailUpdateSuccess)
//            case .failure(let error):
//                let errorDescription = error.localizedDescription
//                DDLogError("⛔️ Error updating Product: \(errorDescription)")
//                // TODO-jc: display error
//                // TODO-jc: analytics
////                ServiceLocator.analytics.track(.productDetailUpdateError)
//                // Dismisses the in-progress UI then presents the error alert.
//            }
//            self.navigationController?.popToViewController(self, animated: true)
//            self.navigationController?.dismiss(animated: true, completion: nil)
//        }
//        ServiceLocator.stores.dispatch(updateProductAction)
    }
}

private extension ProductInventoryScannerViewController {
    func configureNavigation() {
        title = Localization.title

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
    }

    func configureBarcodeScannerChildViewController() {
        let contentView = barcodeScannerChildViewController.view!
        addChild(barcodeScannerChildViewController)
        view.addSubview(contentView)
        barcodeScannerChildViewController.didMove(toParent: self)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToAllEdges(contentView)

        barcodeScannerChildViewController.scannedBarcodes
            .sink { [weak self] barcodes in
                guard let self = self else { return }
                barcodes.forEach { self.searchProductBySKU(barcode: $0) }
            }
            .store(in: &cancellables)
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

private extension ProductInventoryScannerViewController {
    func configureBottomSheetPresentation(for listSelectorViewController: UIViewController) {
        if let sheet = listSelectorViewController.sheetPresentationController {
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.largestUndimmedDetentIdentifier = .large
            sheet.prefersGrabberVisible = true
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom(resolver: { context in
                    context.maximumDetentValue * 0.2
                }), .medium(), .large()]
            } else {
                sheet.detents = [.medium(), .large()]
            }
        }
    }
}

private extension ProductInventoryScannerViewController {
    enum Localization {
        static let title = NSLocalizedString("Update inventory", comment: "Navigation bar title on the inventory scanner screen.")
        static let instructionText = NSLocalizedString("Scan first product barcode",
                                                       comment: "The instruction text below the scan area in the barcode scanner for inventory scanner.")
        static let productFoundStatus = NSLocalizedString("Product Found!", comment: "Status text when a product is found from a barcode in inventory scanner.")
        static let productNotFoundStatus = NSLocalizedString("Product not found",
                comment: "Status text when a product is not found from a bar in inventory scanner.")
        static let searchingProductStatus = NSLocalizedString("Scanning barcode", comment: "Status text when searching a product from a bar in inventory scanner.")
        static let productInventoryUpdateInProgressTitle = NSLocalizedString(
                "Updating inventory",
                comment: "Title of the in-progress UI while updating the Product inventory settings remotely"
        )
        static let productInventoryUpdateInProgressMessage = NSLocalizedString(
                "Please wait while we update inventory for your products",
                comment: "Message of the in-progress UI while updating the Product inventory settings remotely"
        )
    }
}
