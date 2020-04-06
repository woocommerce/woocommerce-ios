import UIKit
import Yosemite

final class ProductSlugViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!
    
    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion

    private let productSettings: ProductSettings
    
    private let sections: [Section]
    
    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
        sections = [Section(rows: [.slug])]
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onCompletion(productSettings)
    }

}

// MARK: - View Configuration
//
private extension ProductSlugViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Slug", comment: "Product Slug navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {

        //tableView.dataSource = self
        //tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }
}

// MARK: - Constants
//
extension ProductSlugViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case slug

        var reuseIdentifier: String {
            switch self {
            case .slug:
                return TextFieldTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
    ///
    struct Section {
        let footer: String?
        let rows: [Row]

        init(footer: String? = nil, rows: [Row]) {
            self.footer = footer
            self.rows = rows
        }

        init(footer: String? = nil, row: Row) {
            self.init(footer: footer, rows: [row])
        }
    }
}
