import UIKit
import WordPressUI

/// Displays a list (implemented by table view) for the user to select a generic model from a bottom sheet.
///
final class BottomSheetListSelectorViewController<Command: BottomSheetListSelectorCommand, Model, Cell>:
UIViewController, UITableViewDataSource, UITableViewDelegate where Command.Model == Model, Command.Cell == Cell {
    private var viewProperties: BottomSheetListSelectorViewProperties
    private var command: Command
    private let onDismiss: ((_ selected: Model?) -> Void)?

    private let rowType = Cell.self

    private let estimatedSectionHeight = CGFloat(44)

    @IBOutlet private(set) weak var tableView: UITableView!

    /// Used for calculating the full content height in `DrawerPresentable` implementation.
    var contentSize: CGSize {
        guard let tableView = tableView else {
            return .zero
        }
        tableView.layoutIfNeeded()
        return tableView.contentSize
    }

    init(viewProperties: BottomSheetListSelectorViewProperties,
         command: Command,
         onDismiss: ((_ selected: Model?) -> Void)?) {
        self.viewProperties = viewProperties
        self.command = command
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configurePreferredContentSize()
    }

    override func viewWillDisappear(_ animated: Bool) {
        onDismiss?(command.selected)
        super.viewWillDisappear(animated)
    }

    func update(command: Command, viewProperties: BottomSheetListSelectorViewProperties? = nil) {
        self.command = command
        if let viewProperties {
            self.viewProperties = viewProperties
        }
        tableView.reloadData()
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
        cell.accessibilityTraits.insert(.button)
        command.configureCell(cell: cell, model: model)

        return cell
    }

    // MARK: UITableViewDelegate
    //
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let selected = command.data[indexPath.row]
        if selected != command.selected {
            command.handleSelectedChange(selected: selected)
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewProperties.title != nil || viewProperties.subtitle != nil else {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: BottomSheetListSelectorSectionHeaderView.reuseIdentifier)
            as? BottomSheetListSelectorSectionHeaderView else {
                fatalError()
        }
        header.configure(title: viewProperties.title, subtitle: viewProperties.subtitle)
        return header
    }
}

// MARK: - View Configuration
//
private extension BottomSheetListSelectorViewController {

    func configureMainView() {
        view.backgroundColor = .listForeground(modal: false)
    }

    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = (viewProperties.title != nil || viewProperties.subtitle != nil) ? estimatedSectionHeight : .zero
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.backgroundColor = .listForeground(modal: false)

        registerTableViewCells()
        registerTableViewHeaderFooters()

        tableView.removeLastCellSeparator()
        tableView.separatorStyle = .none
        tableView.bounces = false
    }

    func registerTableViewCells() {
        if Bundle.main.path(forResource: rowType.classNameWithoutNamespaces, ofType: "nib") != nil {
            tableView.registerNib(for: rowType)
        } else {
            tableView.register(rowType)
        }
    }

    func registerTableViewHeaderFooters() {
        let type = BottomSheetListSelectorSectionHeaderView.self
        tableView.register(type.loadNib(), forHeaderFooterViewReuseIdentifier: type.reuseIdentifier)
    }

    func configurePreferredContentSize() {
        preferredContentSize = contentSize
    }
}
