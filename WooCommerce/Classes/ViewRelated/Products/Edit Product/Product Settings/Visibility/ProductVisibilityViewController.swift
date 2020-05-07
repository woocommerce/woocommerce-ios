import UIKit
import Yosemite

final class ProductVisibilityViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!

    private var sections: [Section] = []
    
    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion

    private let productSettings: ProductSettings
    
    private var visibility: ProductVisibility = .publicVisibility
    
    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
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
        visibility = getProductVisibility(productSettings)
        reloadSections()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onCompletion(productSettings)
    }
    
    func reloadSections() {
        if visibility == .passwordProtected {
            sections = [Section(rows: [.publicVisibility, .passwordVisibility, .passwordField, .privateVisibility])]
        }
        else {
            sections = [Section(rows: [.publicVisibility, .passwordVisibility, .privateVisibility])]
        }
        tableView.reloadData()
    }
    
    /**
    * The visibility is determined by the status and the password. If the password isn't empty, then
    * visibility is `passwordProtected`. If there's no password and the product status is `private`
    * then the visibility is `privateVisibility`, otherwise it's `publicVisibility`.
    */
    func getProductVisibility(_ productSettings: ProductSettings) -> ProductVisibility {
        if productSettings.password?.isNotEmpty == true {
            return .passwordProtected
        }
        else if productSettings.status == .privateStatus {
            return .privateVisibility
        }
        else {
            return .publicVisibility
        }
    }
    
    func getProductStatus(_ productVibility: ProductVisibility) -> ProductStatus {
        switch productVibility {
        case .privateVisibility:
            return .privateStatus
        default:
            return .publish
        }
    }
}

// MARK: - View Configuration
//
private extension ProductVisibilityViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Visibility", comment: "Product Visibility navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.register(BasicTableViewCell.loadNib(), forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductVisibilityViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductVisibilityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        visibility = row.visibility
        productSettings.status = getProductStatus(visibility)
        //productSettings.password = password
        reloadSections()
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductVisibilityViewController {
    
    /// Configure cellForRowAtIndexPath:
    ///
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell:
            configureVisibilityCell(cell: cell, indexPath: indexPath)
        default:
            fatalError("Unidentified product visibility row type")
        }
    }

    func configureVisibilityCell(cell: BasicTableViewCell, indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.selectionStyle = .default
        cell.textLabel?.text = row.description
        if row.editable {
            cell.accessoryType = .none
        }
        else {
            cell.accessoryType = row.visibility == visibility ? .checkmark : .none
        }
    }
}

// MARK: - Constants
//
extension ProductVisibilityViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case publicVisibility
        case passwordVisibility
        case passwordField
        case privateVisibility

        var reuseIdentifier: String {
            switch self {
            case .publicVisibility, .passwordVisibility, .passwordField, .privateVisibility:
                return BasicTableViewCell.reuseIdentifier
            }
        }

        var description: String {
            switch self {
            case .publicVisibility, .passwordVisibility, .privateVisibility:
                return self.visibility.description
            case .passwordField:
                return NSLocalizedString("Password", comment: "One of the possible options in Product Visibility")
            }
        }
        
        var editable: Bool {
            switch self {
            case .passwordField:
                return true
            default:
                return false
            }
        }
        
        var visibility: ProductVisibility {
            switch self {
            case .publicVisibility:
                return .publicVisibility
            case .passwordVisibility, .passwordField:
                return .passwordProtected
            case .privateVisibility:
                return .privateVisibility
            }
        }
    }

    /// Table Sections
    ///
    struct Section {
        let rows: [Row]

        init(rows: [Row]) {
            self.rows = rows
        }

        init(row: Row) {
            self.init(rows: [row])
        }
    }
}
