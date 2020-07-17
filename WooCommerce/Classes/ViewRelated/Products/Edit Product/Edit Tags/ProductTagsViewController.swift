import UIKit
import Yosemite

final class ProductTagsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var sections: [Section] = []

    private var product: Product
    private var tags: [ProductTag]

    // Completion callback
    //
    typealias Completion = (_ tags: [ProductTag]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.product = product
        tags = product.tags
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

// MARK: - UITableViewDataSource Conformance
//
extension ProductTagsViewController: UITableViewDataSource {

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
extension ProductTagsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductTagsViewController {
    /// Configure cellForRowAtIndexPath:
    ///
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextFieldTableViewCell:
            configureSlug(cell: cell)
        case let cell as BasicTableViewCell:
            configureTag(cell: cell)
        default:
            fatalError("Unidentified product slug row type")
        }
    }

    func configureSlug(cell: TextFieldTableViewCell) {
//        cell.accessoryType = .none
//
//        let placeholder = NSLocalizedString("Slug", comment: "Placeholder in the Product Slug row on Edit Product Slug screen.")
//
//        let viewModel = TextFieldTableViewCell.ViewModel(text: productSettings.slug, placeholder: placeholder, onTextChange: { [weak self] newName in
//            if let newName = newName {
//                self?.productSettings.slug = newName
//            }
//            }, onTextDidBeginEditing: {
//                //TODO: Add analytics track
//        }, inputFormatter: nil, keyboardType: .default)
//        cell.configure(viewModel: viewModel)
//        cell.applyStyle(style: .body)
    }

    func configureTag(cell: BasicTableViewCell) {

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
