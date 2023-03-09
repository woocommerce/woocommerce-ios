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
        searchProductBySKU(barcode: "9789863210887")
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
        navigationController?.popToViewController(self, animated: true)
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
        dismissBottomSheetListSelectorIfPresented()
        presentProductInventoryUpdateInProgressUI()
        Task { @MainActor [weak self] in
            guard let self else { return }
            try await self.viewModel.saveResults()
            self.dismiss(animated: true) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    func showInventorySettings(for product: ProductFormDataModel, initialQuantity: Decimal) {
        let inventorySettingsViewController = ProductInventorySettingsViewController(product: product) { [weak self] data in
            self?.updateProductInventorySettings(product, inventoryData: data, initialQuantity: initialQuantity)
        }
        navigationController?.pushViewController(inventorySettingsViewController, animated: true)
    }

    func showProductSelector(for sku: String) {
        let productSelectorViewModel = viewModel.productSelectorViewModel(for: sku) { [weak self] result in
            self?.handleSKUAddedToProduct(result: result)
        }
        let productSelector = ProductSelectorHostingController(configuration: .inventoryScanner, viewModel: productSelectorViewModel)
        navigationController?.pushViewController(productSelector, animated: true)
    }

    func presentProductInventoryUpdateInProgressUI() {
        let viewProperties = InProgressViewProperties(title: Localization.productInventoryUpdateInProgressTitle,
                                                      message: Localization.productInventoryUpdateInProgressMessage)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        inProgressViewController.modalPresentationStyle = .overCurrentContext

        present(inProgressViewController, animated: true)
    }

    func updateProductInventorySettings(_ product: ProductFormDataModel, inventoryData: ProductInventoryEditableData, initialQuantity: Decimal) {
        viewModel.updateInventory(for: product, inventory: inventoryData, initialQuantity: initialQuantity)
        // Navigates back to the scanner screen.
        navigationController?.popToViewController(self, animated: true)
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

private extension ProductSelectorView.Configuration {
    static let inventoryScanner: Self =
        .init(showsFilters: true,
              multipleSelectionsEnabled: false,
              prefersLargeTitle: false,
              title: Localization.title,
              cancelButtonTitle: nil,
              productRowAccessibilityHint: Localization.productRowAccessibilityHint,
              variableProductRowAccessibilityHint: Localization.variableProductRowAccessibilityHint)

    enum Localization {
        static let title = NSLocalizedString("Products", comment: "Title for the screen to select a product for a scanned SKU.")
        static let productRowAccessibilityHint = NSLocalizedString(
            "Selection of a product for a scanned SKU in inventory scanner.",
            comment: "Accessibility hint for selecting a product for a scanned SKU in inventory scanner."
        )
        static let variableProductRowAccessibilityHint = NSLocalizedString(
            "Opens list of product variations.",
            comment: "Accessibility hint for selecting a variable product in the Select Products screen"
        )
        static let doneButtonSingular = NSLocalizedString(
            "Select 1 Product",
            comment: "Title of the action button at the bottom of the Select Products screen when one product is selected"
        )
        static let doneButtonPlural = NSLocalizedString(
            "Select %1$d Products",
            comment: "Title of the action button at the bottom of the Select Products screen " +
            "when more than 1 item is selected, reads like: Select 5 Products"
        )
    }
}
