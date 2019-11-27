import UIKit

protocol ListSelectorDataSource {
    associatedtype Model: Equatable

    var data: [Model] { get }

    var selected: Model? { get }

    mutating func handleSelectedChange(selected: Model)

    func configureCell(cell: BasicTableViewCell, model: Model)
}

struct ListSelectorViewModel {
    let navigationBarTitle: String?
}

final class ListSelectorViewController<DataSource: ListSelectorDataSource, Model>:
UIViewController, UITableViewDataSource, UITableViewDelegate where DataSource.Model == Model {
    private let viewModel: ListSelectorViewModel
    private var dataSource: DataSource

    private let rowType = BasicTableViewCell.self

    private let onDismiss: (_ selected: Model?) -> Void

    @IBOutlet private weak var tableView: UITableView!

    init(viewModel: ListSelectorViewModel,
         dataSource: DataSource,
         onDismiss: @escaping (_ selected: Model?) -> Void) {
        self.viewModel = viewModel
        self.dataSource = dataSource
        self.onDismiss = onDismiss
        super.init(nibName: "ListSelectorViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        onDismiss(dataSource.selected)
        super.viewWillDisappear(animated)
    }

    // MARK: UITableViewDataSource
    //
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: rowType.reuseIdentifier,
                                                       for: indexPath) as? BasicTableViewCell else {
                                                        fatalError()
        }
        let model = dataSource.data[indexPath.row]
        dataSource.configureCell(cell: cell, model: model)

        cell.accessoryType = model == dataSource.selected ? .checkmark: .none

        return cell
    }

    // MARK: UITableViewDelegate
    //
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selected = dataSource.data[indexPath.row]
        if selected != dataSource.selected {
            dataSource.handleSelectedChange(selected: selected)
            tableView.reloadData()
        }
    }
}

// MARK: - View Configuration
//
private extension ListSelectorViewController {

    func configureNavigation() {
        title = viewModel.navigationBarTitle
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewCells()
    }

    func registerTableViewCells() {
        tableView.register(rowType.loadNib(), forCellReuseIdentifier: rowType.reuseIdentifier)
    }
}
