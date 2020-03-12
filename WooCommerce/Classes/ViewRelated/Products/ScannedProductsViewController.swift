import UIKit
import Yosemite

final class ScannedProductsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let imageService: ImageService

    private var scannedProducts: [Product] = []
    private var stockQuantitiesByProductID: [Int64: Int] = [:]

    private let onSaveCompletion: () -> Void

    init(imageService: ImageService = ServiceLocator.imageService, onSaveCompletion: @escaping () -> Void) {
        self.imageService = imageService
        self.onSaveCompletion = onSaveCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .basicBackground
        configureNavigation()
        configureTableView()
    }

    func productScanned(product: Product) {
        if let matchedProduct = scannedProducts.first(where: { $0.sku == product.sku }),
            let quantity = stockQuantitiesByProductID[matchedProduct.productID] {
            stockQuantitiesByProductID[matchedProduct.productID] = quantity + 1

            reloadDataIfPossible()

            return
        }

        scannedProducts.append(product)

        guard product.manageStock else {
            // TODO-jc: handle when product stock managemnet isn't enabled
            return
        }
        stockQuantitiesByProductID[product.productID] = (product.stockQuantity ?? 0) + 1

        reloadDataIfPossible()
    }

    private func reloadDataIfPossible() {
        guard isViewLoaded else {
            return
        }
        tableView.reloadData()
    }
}

// MARK: - Navigation
//
private extension ScannedProductsViewController {
    @objc func saveButtonTapped() {
        // TODO-jc
        let group = DispatchGroup()
        
        scannedProducts.forEach { product in
            group.enter()
            let stockQuantity = stockQuantitiesByProductID[product.productID]
            let product = product.inventorySettingsUpdated(sku: product.sku,
                                                                  manageStock: product.manageStock,
                                                                  soldIndividually: product.soldIndividually,
                                                                  stockQuantity: stockQuantity,
                                                                  backordersSetting: product.backordersSetting,
                                                                  stockStatus: product.productStockStatus)
            let action = ProductAction.updateProduct(product: product) { (updatedProduct, error) in
                group.leave()
            }
            ServiceLocator.stores.dispatch(action)
        }

        group.notify(queue: .main) { [weak self] in
            self?.onSaveCompletion()
        }
    }
}

// MARK: - Configurations
//
private extension ScannedProductsViewController {
    func configureNavigation() {
        title = NSLocalizedString("Scanned Products", comment: "")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonTapped))
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        let cells = [
            ProductDetailsTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }

        let headersAndFooters = [
            TwoColumnSectionHeaderView.self
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }

        tableView.estimatedSectionHeaderHeight = 80
        tableView.tableFooterView = UIView()

        tableView.reloadData()
    }
}

extension ScannedProductsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedProducts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductDetailsTableViewCell.reuseIdentifier, for: indexPath) as? ProductDetailsTableViewCell else {
            fatalError()
        }
        let product = scannedProducts[indexPath.row]
        cell.configureForInventoryScannerResult(product: product, updatedQuantity: stockQuantitiesByProductID[product.productID], imageService: imageService)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension ScannedProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO-jc
        let product = scannedProducts[indexPath.row]
        let inventorySettingsViewController =
            ProductStockSettingsViewController(product: product,
                                               stockQuantity: stockQuantitiesByProductID[product.productID]) {
                                                [weak self] stockData in
                                                let updatedProduct = product.inventorySettingsUpdated(sku: product.sku,
                                                                                                      manageStock: stockData.manageStock,
                                                                                                      soldIndividually: product.soldIndividually,
                                                                                                      stockQuantity: product.stockQuantity,
                                                                                                      backordersSetting: stockData.backordersSetting,
                                                                                                      stockStatus: stockData.stockStatus)
                                                self?.scannedProducts[indexPath.row] = updatedProduct
                                                self?.stockQuantitiesByProductID[updatedProduct.productID] = stockData.stockQuantity ?? product.stockQuantity ?? 0
                                                self?.reloadDataIfPossible()
                                                self?.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(inventorySettingsViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TwoColumnSectionHeaderView.reuseIdentifier) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = NSLocalizedString("PRODUCT", comment: "Product section title")
        headerView.rightText = NSLocalizedString("QUANTITY", comment: "Quantity abbreviation for section title")

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}
