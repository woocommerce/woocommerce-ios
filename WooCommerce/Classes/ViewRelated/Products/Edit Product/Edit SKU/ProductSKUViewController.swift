import UIKit

final class ProductSKUViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    // Completion callback
    //
    typealias Completion = (_ sku: String?) -> Void
    private let onCompletion: Completion

    private let originalSKU: String?
    private var sku: String?

    private let sections: [Section]

    // Sku validation
    private var skuIsValid: Bool = true

    private lazy var throttler: Throttler = Throttler(seconds: 0.5)

    /// Init
    ///
    init(sku: String?, completion: @escaping Completion) {
        self.originalSKU = sku
        self.sku = sku
        let footerText = NSLocalizedString("Helps to easily identify this product", comment: "Footer text in Edit Product SKU screen")
        sections = [Section(footer: footerText, rows: [.sku])]
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureFirstTextFieldAsFirstResponder()
    }
}

// MARK: - Navigation actions handling
//
extension ProductSKUViewController {
    override func shouldPopOnBackButton() -> Bool {
        guard skuIsValid else {
            return true
        }

        if originalSKU != sku {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeEditing() {
        if skuIsValid {
            onCompletion(sku)
        }
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - View Configuration
//
private extension ProductSKUViewController {
    func configureNavigationBar() {
        title = NSLocalizedString("SKU", comment: "Edit Product SKU navigation title")

        // TODO: DONE button
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeEditing))
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.register(TextFieldTableViewCell.loadNib(), forCellReuseIdentifier: TextFieldTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension

        tableView.allowsSelection = false
    }

    /// Since there is only a text field in this view, the text field become the first responder immediately when the view did appear
    ///
    func configureFirstTextFieldAsFirstResponder() {
        if let indexPath = sections.indexPathForRow(.sku) {
            let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell
            cell?.becomeFirstResponder()
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductSKUViewController: UITableViewDataSource {
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
extension ProductSKUViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductSKUViewController {
    /// Configure cellForRowAtIndexPath:
    ///
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextFieldTableViewCell:
            configureSKU(cell: cell)
        default:
            fatalError("Unidentified row type: \(row)")
        }
    }

    func configureSKU(cell: TextFieldTableViewCell) {
        cell.accessoryType = .none

        let placeholder = NSLocalizedString("Enter SKU", comment: "Placeholder in the Product SKU row on Edit Product SKU screen.")

        let viewModel = TextFieldTableViewCell.ViewModel(text: sku,
                                                         placeholder: placeholder,
                                                         onTextChange: { [weak self] sku in
                                                            self?.sku = sku
            }, onTextDidBeginEditing: {
                // TODO-2000: Edit Product M3 analytics
        }, inputFormatter: StringInputFormatter(), keyboardType: .default)
        cell.configure(viewModel: viewModel)
        cell.applyStyle(style: .body)
    }
}

// MARK: - Constants
//
private extension ProductSKUViewController {
    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case sku

        var reuseIdentifier: String {
            switch self {
            case .sku:
                return TextFieldTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
    ///
    struct Section: RowIterable {
        let footer: String?
        let rows: [Row]

        init(footer: String? = nil, rows: [Row]) {
            self.footer = footer
            self.rows = rows
        }
    }
}
