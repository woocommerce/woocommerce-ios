import UIKit
import Yosemite

final class ScannedProductsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let imageService: ImageService

    private var scannedProducts: [Product] = []

    init(imageService: ImageService = ServiceLocator.imageService) {
        self.imageService = imageService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
    }

    func productScanned(product: Product) {
        scannedProducts.append(product)

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
        cell.configureForInventoryScannerResult(product: product, imageService: imageService)
        return cell
    }
}

extension ScannedProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // TODO-jc
    }
}
