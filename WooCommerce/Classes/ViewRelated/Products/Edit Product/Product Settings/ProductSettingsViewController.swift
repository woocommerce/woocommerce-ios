import UIKit
import Yosemite

// MARK: - ProductSettingsViewController
//
final class ProductSettingsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var viewModel: ProductSettingsTableViewModel
    
    init(product: Product) {
        self.viewModel = ProductSettingsTableViewModel(product: product)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

// MARK: - View Configuration
//
private extension ProductSettingsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Product Settings", comment: "Product Settings navigation title")
        
        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        viewModel.registerTableViewCells(tableView)

        //tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource Conformance
//
//extension ProductSettingsViewController: UITableViewDataSource {
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return sections.count
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return sections[section].rows.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        return cell
//    }
//}

// MARK: - UITableViewDelegate Conformance
//
extension ProductSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
