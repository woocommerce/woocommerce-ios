import UIKit

/// Displays a list (implemented by table view) for the user to select a generic model from a bottom sheet.
///
final class BottomSheetListSelectorViewController<DataSource: BottomSheetListSelectorCommand, Model, Cell>:
UIViewController, UITableViewDataSource, UITableViewDelegate where DataSource.Model == Model, DataSource.Cell == Cell {
    private let viewProperties: BottomSheetListSelectorViewController.ViewProperties
    private var dataSource: DataSource
    private let onDismiss: (_ selected: Model?) -> Void

    private let rowType = Cell.self

    private let estimatedSectionHeight = CGFloat(44)

    @IBOutlet private(set) weak var tableView: UITableView!

    init(viewProperties: BottomSheetListSelectorViewController.ViewProperties,
         dataSource: DataSource,
         onDismiss: @escaping (_ selected: Model?) -> Void) {
        self.viewProperties = viewProperties
        self.dataSource = dataSource
        self.onDismiss = onDismiss
        super.init(nibName: "BottomSheetListSelectorViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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
                                                       for: indexPath) as? Cell else {
                                                        fatalError()
        }
        let model = dataSource.data[indexPath.row]
        dataSource.configureCell(cell: cell, model: model)

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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: BottomSheetListSelectorSectionHeaderView.reuseIdentifier)
            as? BottomSheetListSelectorSectionHeaderView else {
                fatalError()
        }
        header.configure(text: viewProperties.title)
        return header
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return estimatedSectionHeight
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - View Configuration
//
private extension BottomSheetListSelectorViewController {

    func configureMainView() {
        view.backgroundColor = .listForeground
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listForeground

        registerTableViewCells()
        registerTableViewHeaderFooters()

        tableView.removeLastCellSeparator()
        tableView.separatorStyle = .none
        tableView.bounces = false
    }

    func registerTableViewCells() {
        tableView.register(rowType.loadNib(), forCellReuseIdentifier: rowType.reuseIdentifier)
    }

    func registerTableViewHeaderFooters() {
        let headersAndFooters = [BottomSheetListSelectorSectionHeaderView.self]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}
