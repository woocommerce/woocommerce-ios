import UIKit
import WordPressUI
import Yosemite

struct ScannedProductsBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = Product
    typealias Cell = ProductDetailsTableViewCell

    let data: [Product]

    let selected: Product? = nil

    private let imageService: ImageService
    private let onSelection: (Product) -> Void

    init(products: [Product],
         imageService: ImageService = ServiceLocator.imageService,
         onSelection: @escaping (Product) -> Void) {
        self.onSelection = onSelection
        self.imageService = imageService
        self.data = products
    }

    func configureCell(cell: ProductDetailsTableViewCell, model: Product) {
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator

        // TODO-jc: stock quantity tracking
        cell.configureForInventoryScannerResult(product: model, updatedQuantity: model.stockQuantity, imageService: imageService)
    }

    func handleSelectedChange(selected: Product) {
        onSelection(selected)
    }

    func isSelected(model: Product) -> Bool {
        return model == selected
    }
}

enum ProductSKUScannerResult {
    case matched(product: Product)
    case noMatch(sku: String)
}

final class ProductStockScannerViewController: UIViewController {

    private lazy var barcodeScannerChildViewController : BarcodeScannerViewController = {
        return BarcodeScannerViewController { [weak self] (barcodes, error) in
            guard let barcode = barcodes.first else {
                return
            }
            self?.searchProductBySKU(barcode: barcode)
        }
    }()

    private var scannedProducts: [Product] = []

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO-jc: remove. this is just for testing
        searchProductBySKU(barcode: "9789863210887")
    }
}

// MARK: Search
//
private extension ProductStockScannerViewController {
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

                    self.scannedProducts.append(product)
                    self.presentSearchResults()
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

    func presentSearchResults() {
        // TODO-jc: singular vs. plural
        let title = NSLocalizedString("Scanned products",
                                      comment: "Title of the bottom sheet that shows a list of scanned products via the barcode scanner.")
        let viewProperties = BottomSheetListSelectorViewProperties(title: title)
        let dataSource = ScannedProductsBottomSheetListSelectorCommand(products: scannedProducts) { [weak self] action in
                                                                    self?.dismiss(animated: true) { [weak self] in

                                                                    }
        }
        let listSelectorViewController = BottomSheetListSelectorViewController(viewProperties: viewProperties,
                                                                               command: dataSource) { [weak self] selectedSortOrder in
                                                                                self?.dismiss(animated: true, completion: nil)
        }
        let bottomSheet = BottomSheetViewController(childViewController: listSelectorViewController)
        bottomSheet.show(from: self, sourceView: nil, arrowDirections: .any)
    }
}

// MARK: Navigation
//
private extension ProductStockScannerViewController {
    @objc func doneButtonTapped() {
        // TODO-jc
    }
}

private extension ProductStockScannerViewController {
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
private extension ProductStockScannerViewController {
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
