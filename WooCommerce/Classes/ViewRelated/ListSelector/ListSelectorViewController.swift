import UIKit

/// A generic data source for the list selector UI `ListSelectorViewController`.
///
protocol ListSelectorCommand {
    associatedtype Model
    associatedtype Cell: UITableViewCell
    typealias ViewController = ListSelectorViewController<Self, Model, Cell>

    /// Title of the navigation bar.
    var navigationBarTitle: String? { get }

    /// A list of models to render the list.
    var data: [Model] { get }

    /// The model that is currently selected in the list.
    var selected: Model? { get }

    /// Called when a different model is selected.
    /// - Parameters:
    ///   - selected: the model that is selected by the user.
    ///   - viewController: the list selector view controller.
    func handleSelectedChange(selected: Model, viewController: ViewController)

    /// Configures the selected UI.
    func isSelected(model: Model) -> Bool

    /// Configures the cell with the given model.
    func configureCell(cell: Cell, model: Model)
}

/// Displays a list (implemented by table view) for the user to select a generic model.
///
final class ListSelectorViewController<Command: ListSelectorCommand, Model, Cell>:
UIViewController, UITableViewDataSource, UITableViewDelegate where Command.Model == Model, Command.Cell == Cell {
    private let command: Command
    private let tableViewStyle: UITableView.Style
    private let onDismiss: (_ selected: Model?) -> Void

    private let rowType = Cell.self

    private lazy var tableView: UITableView = {
        return UITableView(frame: .zero, style: tableViewStyle)
    }()

    init(command: Command,
         tableViewStyle: UITableView.Style = .grouped,
         onDismiss: @escaping (_ selected: Model?) -> Void) {
        self.command = command
        self.tableViewStyle = tableViewStyle
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
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
        if isMovingFromParent {
            onDismiss(command.selected)
        }
        super.viewWillDisappear(animated)
    }

    func reloadData() {
        tableView.reloadData()

        title = command.navigationBarTitle
    }

    // MARK: UITableViewDataSource
    //
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return command.data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(Cell.self, for: indexPath)
        let model = command.data[indexPath.row]
        // Configures the cell's `accessoryType` before calling `command.configureCell` so that the command could override the `accessoryType`.
        cell.accessoryType = command.isSelected(model: model) ? .checkmark: .none
        command.configureCell(cell: cell, model: model)

        return cell
    }

    // MARK: UITableViewDelegate
    //
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selected = command.data[indexPath.row]
        if !command.isSelected(model: selected) {
            command.handleSelectedChange(selected: selected, viewController: self)
            tableView.reloadData()
        }
    }
}

// MARK: - View Configuration
//
private extension ListSelectorViewController {

    func configureNavigation() {
        title = command.navigationBarTitle
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)

        registerTableViewCells()
    }

    func registerTableViewCells() {
        tableView.registerNib(for: rowType)
    }
}
