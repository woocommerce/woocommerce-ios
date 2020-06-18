import UIKit

/// AddProductCategoryViewController: Add a new category associated to the active Account.
///
final class AddProductCategoryViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!


    /// Table Sections to be rendered
    ///
    private var sections: [Section] = [Section(rows: [.title]), Section(rows: [.parentCategory])]

    init() {
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
    }
}

// MARK: - View Configuration
//
private extension AddProductCategoryViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Add Category", comment: "Product Add Category navigation title")

        //navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeUpdating))
        //removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddProductCategoryViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        //configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AddProductCategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
}

// MARK: - Private Types
//
private extension AddProductCategoryViewController {

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case title
        case parentCategory

        var type: UITableViewCell.Type {
            switch self {
            case .title:
                return TitleAndTextFieldTableViewCell.self
            case .parentCategory:
                return SettingTitleAndValueTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
