import UIKit
import Yosemite

final class ProductTagsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var sections: [Section] = []

    // Completion callback
    //
    typealias Completion = (_ tags: [ProductTag]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTableView()
        registerTableViewCells(tableView)
    }

}

// MARK: - View Configuration
//
private extension ProductTagsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Tags", comment: "Product Tags navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.register(TextFieldTableViewCell.loadNib(), forCellReuseIdentifier: TextFieldTableViewCell.reuseIdentifier)

        //tableView.dataSource = self
        //tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    /// Since there is only a text field in this view, the text field become the first responder immediately when the view did appear
    ///
//    func configureTextFieldFirstResponder() {
//        if let indexPath = sections.indexPathForRow(.slug) {
//            let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell
//            cell?.becomeFirstResponder()
//        }
//    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        sections.flatMap {
            $0.rows.compactMap { $0.cellType }
        }.forEach {
            tableView.register($0.loadNib(), forCellReuseIdentifier: $0.reuseIdentifier)
        }
    }
}

// MARK: - Constants
//
private extension ProductTagsViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case tagsTextField
        case tag

        /// Returns the Row's Reuse Identifier
        ///
        var reuseIdentifier: String {
            return cellType.reuseIdentifier
        }

        /// Returns the Row's Cell Type
        ///
        var cellType: UITableViewCell.Type {
            switch self {
            case .tagsTextField:
                return TextFieldTableViewCell.self
            case .tag:
                return BasicTableViewCell.self
            }
        }
    }

    /// Table Sections
    ///
    struct Section: RowIterable {
        let rows: [Row]

        init(rows: [Row]) {
            self.rows = rows
        }
    }
}
