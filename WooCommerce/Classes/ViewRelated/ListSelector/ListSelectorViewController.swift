import UIKit

protocol ListSelectorDataSource {
    associatedtype Model: Equatable

    var data: [Model] { get }

    var selected: Model? { get }

    var onSelectedChange: (_ selected: Model) -> Void { get }

    func configureCell(cell: BasicTableViewCell, model: Model)
}

struct ListSelectorViewModel {
    let navigationBarTitle: String?
}

final class ListSelectorViewController<DataSource: ListSelectorDataSource>: UIViewController, UITableViewDataSource {
    private let viewModel: ListSelectorViewModel
    private let dataSource: DataSource

    private let rowType = BasicTableViewCell.self

    @IBOutlet weak var tableView: UITableView!
    init(viewModel: ListSelectorViewModel, dataSource: DataSource) {
        self.viewModel = viewModel
        self.dataSource = dataSource
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

        if model == dataSource.selected {
            cell.accessoryType = .checkmark
        }

        return cell
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
//        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewCells()
    }

    func registerTableViewCells() {
        tableView.register(rowType.loadNib(), forCellReuseIdentifier: rowType.reuseIdentifier)
    }
}
