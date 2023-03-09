import Combine
import UIKit
import WordPressUI
import Yosemite

final class ProductInventoryScannerViewController: UIViewController {
    // MARK: - Navigation actions that are set externally (e.g. by a coordinator)
    var showInventorySettings: ((_ product: ProductFormDataModel) async -> ProductInventoryEditableData?)?
    var showProductSelector: ((_ sku: String, _ viewModel: ProductSelectorViewModel) -> Void)?
    var showInProgressUIAddingSKUToProduct: ((_ task: @escaping () async throws -> Void) -> Void)?
    var confirmAddingSKUToProductWithStockManagementEnabled: ((_ product: ProductFormDataModel) async -> ProductFormDataModel?)?
    var onSave: ((_ task: @escaping () async throws -> Void) -> Void)?

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

        configureView()
        configureNavigation()
        configureBarcodeScannerChildViewController()
        configureStatusLabel()
        observeResults()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presentBottomSheetListSelectorIfNotPresented()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO-jc: remove. this is just for testing
    }

    override func viewWillDisappear(_ animated: Bool) {
        dismissBottomSheetListSelectorIfPresented()

        super.viewWillDisappear(animated)
    }
}

// MARK: Search
//
private extension ProductInventoryScannerViewController {
    func searchProductBySKU(barcode: String) {
        showStatusLabel(text: Localization.searchingProductStatus, status: .refunded)

        Task { @MainActor in
            let result = await Result { try await viewModel.searchProductBySKU(barcode: barcode) }
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
        case .failure:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            showStatusLabel(text: Localization.productNotFoundStatus, status: .failed)
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
                case .matched(let product, let initialQuantity):
                    self.showInventorySettings(for: product, initialQuantity: initialQuantity)
                case .noMatch(let sku):
                    self.showProductSelector(for: sku)
                }
            }
        }

        if let listSelectorViewController {
            listSelectorViewController.update(command: command, viewProperties: viewProperties)
        } else {
            let listSelectorViewController = BottomSheetListSelectorViewController(viewProperties: viewProperties,
                                                                                   command: command) { [weak self] selectedSortOrder in
                self?.dismiss(animated: true, completion: nil)
            }
            self.listSelectorViewController = listSelectorViewController
        }

        // Only presents the bottom sheet if it hasn't been presented.
        guard let listSelectorViewController, listSelectorViewController.presentingViewController == nil else {
            return
        }

        configureBottomSheetPresentation(for: listSelectorViewController)
        listSelectorViewController.isModalInPresentation = true
        present(listSelectorViewController, animated: true)
    }

    @MainActor
    func handleSKUAddedToProduct(result: Result<ProductFormDataModel, Error>) {
        switch result {
        case .success:
            showStatusLabel(text: NSLocalizedString("Barcode saved!", comment: ""), status: .processing)
        case .failure(let error):
            showStatusLabel(text: error.localizedDescription, status: .failed)
        }
    }
}

// MARK: Navigation
//
private extension ProductInventoryScannerViewController {
    @objc func saveButtonTapped() {
        guard let onSave else {
            return
        }
        dismissBottomSheetListSelectorIfPresented()
        onSave {
            try await self.viewModel.saveResults()
        }
    }

    func showInventorySettings(for product: ProductFormDataModel, initialQuantity: Decimal) {
        Task { @MainActor [weak self] in
            guard let self, let showInventorySettings = self.showInventorySettings else { return }
            guard let data = await showInventorySettings(product) else {
                return
            }
            self.updateProductInventorySettings(product, inventoryData: data, initialQuantity: initialQuantity)
        }
    }

    func showProductSelector(for sku: String) {
        guard let showProductSelector else {
            return
        }
        let productSelectorViewModel = viewModel.productSelectorViewModel(for: sku) { [weak self] selectedProduct in
            guard let self,
                  let confirmAddingSKUToProductWithStockManagementEnabled = self.confirmAddingSKUToProductWithStockManagementEnabled,
                  let showInProgressUIAddingSKUToProduct = self.showInProgressUIAddingSKUToProduct else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard let confirmedProduct = await confirmAddingSKUToProductWithStockManagementEnabled(selectedProduct) else {
                    return
                }
                showInProgressUIAddingSKUToProduct {
                    let result = await Result { try await self.viewModel.addSKUToProduct(sku: sku, product: confirmedProduct) }
                    self.handleSKUAddedToProduct(result: result)
                }
            }
        }
        showProductSelector(sku, productSelectorViewModel)
    }

    func updateProductInventorySettings(_ product: ProductFormDataModel, inventoryData: ProductInventoryEditableData, initialQuantity: Decimal) {
        viewModel.updateInventory(for: product, inventory: inventoryData, initialQuantity: initialQuantity)
    }

    func presentBottomSheetListSelectorIfNotPresented() {
        if let listSelectorViewController, listSelectorViewController.presentingViewController == nil {
            configureBottomSheetPresentation(for: listSelectorViewController)
            present(listSelectorViewController, animated: true)
        }
    }

    func dismissBottomSheetListSelectorIfPresented() {
        if let listSelectorViewController, listSelectorViewController.presentingViewController != nil {
            listSelectorViewController.dismiss(animated: true)
        }
    }
}

private extension ProductInventoryScannerViewController {
    func configureView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        title = Localization.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
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
            }.store(in: &subscriptions)
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

// MARK: - Bottom sheet
//
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
        static let scannedProductHeader = NSLocalizedString("Scanned product",
                                                            comment: "Bottom sheet header for a one scanned product in inventory scanner.")
        static let scannedProductsHeader = NSLocalizedString("Scanned products",
                                                            comment: "Bottom sheet header for a list of scanned products in inventory scanner.")
    }
}
