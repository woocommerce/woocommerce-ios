import UIKit
import Yosemite

final class RenameAttributesViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!

    private let onCompletion: (String) -> Void

    private let viewModel: RenameAttributesViewModel

    private let sections: [Section]

    /// Initializer for `RenameAttributesViewController`
    ///
    init(viewModel: RenameAttributesViewModel,
         onCompletion: @escaping (String) -> Void) {
        self.viewModel = viewModel
        self.onCompletion = onCompletion
        self.sections = [Section(footer: Localization.footerText, rows: [.attributeName])]
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
        enableDoneButton(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureTextFieldFirstResponder()
    }
}

// MARK: - View Configuration
//
private extension RenameAttributesViewController {

    func configureNavigationBar() {
        removeNavigationBackBarButtonText()
        title = Localization.title

        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                             target: self,
                                             action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }

    func enableDoneButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.registerNib(for: TextFieldTableViewCell.self)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    /// Since there is only a text field in this view, the text field becomes the first responder immediately when the view did appear
    ///
    func configureTextFieldFirstResponder() {
        if let indexPath = sections.indexPathForRow(.attributeName) {
            let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell
            cell?.becomeFirstResponder()
        }
    }
}

// MARK: - Navigation actions handling

extension RenameAttributesViewController {
    @objc private func doneButtonTapped() {
        onCompletion(viewModel.attributeName)
    }

    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.hasUnsavedChanges() else {
            return true
        }
        presentBackNavigationActionSheet()
        return false
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension RenameAttributesViewController: UITableViewDataSource {

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
extension RenameAttributesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension RenameAttributesViewController {
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextFieldTableViewCell:
            configureAttributeName(cell: cell)
        default:
            fatalError("Unidentified attribute row type")
        }
    }

    func configureAttributeName(cell: TextFieldTableViewCell) {
        cell.accessoryType = .none

        let placeholder = Localization.placeholder

        let cellViewModel = TextFieldTableViewCell.ViewModel(text: viewModel.attributeName,
                                                         placeholder: placeholder,
                                                         onTextChange: { [weak self] newAttributeName in
                                                            guard let self = self else {return}
                                                            self.viewModel.handleAttributeNameChange(newAttributeName)
                                                            self.enableDoneButton(self.viewModel.shouldEnableDoneButton)
                                                         },
                                                         onTextDidBeginEditing: nil,
                                                         onTextDidReturn: { [weak self] _ in
                                                            self?.doneButtonTapped()
                                                         },
                                                         inputFormatter: nil,
                                                         keyboardType: .default,
                                                         returnKeyType: .done)
        cell.configure(viewModel: cellViewModel)
        cell.applyStyle(style: .body)
    }
}

// MARK: - Constants
//
private extension RenameAttributesViewController {

    /// Table Rows
    ///
    enum Row {
        case attributeName

        var reuseIdentifier: String {
            switch self {
            case .attributeName:
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


// MARK: - Constants
private extension RenameAttributesViewController {

    enum Localization {
        static let title = NSLocalizedString("Rename Attribute", comment: "Navigation title for the Rename Attributes screen")
        static let placeholder = NSLocalizedString("Attribute name", comment: "Placeholder in the Attribute Name row on Rename Attributes screen.")
        static let footerText = NSLocalizedString("This is the type of variation like size or color",
        comment: "Footer text in Rename Attributes screen")
    }
}
