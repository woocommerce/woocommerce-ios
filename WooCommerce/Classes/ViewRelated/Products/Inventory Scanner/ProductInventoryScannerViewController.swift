import Combine
import UIKit
import WordPressUI
import Yosemite

final class ProductInventoryScannerViewController: UIViewController {
    private lazy var barcodeScannerChildViewController = BarcodeScannerViewController(instructionText: Localization.instructionText)

    private var listSelectorViewController: BottomSheetListSelectorViewController
    <ScannedProductsBottomSheetListSelectorCommand, ProductSKUScannerResult, ProductsTabProductTableViewCell>?

    private lazy var statusLabel: PaddedLabel = {
        let label = PaddedLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let viewModel: ProductInventoryScannerViewModel

    private var subscriptions: Set<AnyCancellable> = []

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
        observeResults()
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
        showStatusLabel(text: Localization.searchingProductStatus, status: .refunded)

        Task { @MainActor in
            let result = await viewModel.searchProductBySKU(barcode: barcode)
            handleProductSearch(result: result, barcode: barcode)
        }
    }

    @MainActor
    func handleProductSearch(result: Result<Void, Error>, barcode: String) {
        switch result {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            showStatusLabel(text: Localization.productFoundStatus, status: .processing)
        case .failure(let error):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            showStatusLabel(text: Localization.productNotFoundStatus, status: .failed)

            print("No product matched: \(error)")
        }
    }

    @MainActor
    func presentSearchResults(_ results: [ProductSKUScannerResult]) {
        guard results.isNotEmpty else {
            return
        }
        let title = results.count > 1 ? Localization.scannedProductsHeader: Localization.scannedProductHeader
        let viewProperties = BottomSheetListSelectorViewProperties(subtitle: title)
        let command = ScannedProductsBottomSheetListSelectorCommand(results: results) { [weak self] result in
            self?.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                switch result {
                case .matched(let product):
                    self.editInventorySettings(for: product)
                case .noMatch(let sku):
                    // TODO: 2407 - navigate to let the user add the SKU to a product
                    print("TODO: \(sku)")
                }
            }
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

    func presentProductInventoryUpdateInProgressUI() {
        let viewProperties = InProgressViewProperties(title: Localization.productInventoryUpdateInProgressTitle,
                                                      message: Localization.productInventoryUpdateInProgressMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext

        present(inProgressViewController, animated: true)
    }

    func updateProductInventorySettings(_ product: ProductFormDataModel, inventoryData: ProductInventoryEditableData) {
        viewModel.updateInventory(for: product, inventory: inventoryData)
        // Navigates back to the scanner screen.
        navigationController?.popToViewController(self, animated: true)
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
            .store(in: &subscriptions)
    }

    func configureStatusLabel() {
        view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            statusLabel.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 20)
        ])

        hideStatusLabel()
    }

    func observeResults() {
        viewModel.$results.sink { [weak self] results in
            guard let self else { return }
            self.presentSearchResults(results)
        }.store(in: &subscriptions)
    }
}

// MARK: Status UI
//
private extension ProductInventoryScannerViewController {
    func showStatusLabel(text: String, status: OrderStatusEnum) {
        statusLabel.applyStyle(for: status)
        statusLabel.text = text
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
        static let searchingProductStatus = NSLocalizedString("Scanning barcode",
                                                              comment: "Status text when searching a product from a bar in inventory scanner.")
        static let productInventoryUpdateInProgressTitle = NSLocalizedString(
                "Updating inventory",
                comment: "Title of the in-progress UI while updating the Product inventory settings remotely."
        )
        static let productInventoryUpdateInProgressMessage = NSLocalizedString(
                "Please wait while we update inventory for your products",
                comment: "Message of the in-progress UI while updating the Product inventory settings remotely"
        )
        static let scannedProductHeader = NSLocalizedString("Scanned product",
                                                            comment: "Bottom sheet header for a one scanned product in inventory scanner.")
        static let scannedProductsHeader = NSLocalizedString("Scanned products",
                                                            comment: "Bottom sheet header for a list of scanned products in inventory scanner.")
    }
}
