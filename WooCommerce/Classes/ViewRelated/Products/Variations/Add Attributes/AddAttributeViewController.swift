import UIKit
import Yosemite

final class AddAttributeViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: AddAttributeViewModel
    
    /// Init
    ///
    init(attributes: [ProductAttribute]) {
        self.product = product
        viewModel = AddAttributeViewModel(attributes: attributes)
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
        registerTableViewCells()
    }


}

// MARK: - View Configuration
//
private extension AddAttributeViewController {

    func configureNavigationBar() {
        title = Localization.titleView

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Localization.nextNavBarButton,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(completeUpdating))
    }

    func configureMainView() {
        view.backgroundColor = .listForeground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listForeground
        tableView.separatorStyle = .none

        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddAttributeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AddAttributeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Cell configuration
//
private extension AddAttributeViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextFieldTableViewCell where row == .attributeTextField:
            configureTextField(cell: cell)
        case let cell as BasicTableViewCell where row == .existingAttribute:
            configureAttribute(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureTextField(cell: TextFieldTableViewCell) {
        
    }
    
    func configureAttribute(cell: BasicTableViewCell) {
        
    }
}


// MARK: - Navigation actions handling
//
extension AddAttributeViewController {


    @objc private func completeUpdating() {
        // TODO: to be implemented
    }
}

extension AddAttributeViewController {

    struct Section: Equatable {
        let header: String?
        let footer: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case attributeTextField
        case existingAttribute

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .attributeTextField:
                return TextFieldTableViewCell.self
            case .existingAttribute:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension AddAttributeViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Add attribute", comment: "Add Attribute screen navigation title")
        static let nextNavBarButton = NSLocalizedString("Next", comment: "Next nav bar button title in Add Attribute screen")
    }
}
