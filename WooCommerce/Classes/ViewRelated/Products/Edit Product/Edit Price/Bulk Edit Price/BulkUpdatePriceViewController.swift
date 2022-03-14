import Foundation
import UIKit
import Yosemite
import Combine
import WordPressKit

// MARK: - BulkUpdatePriceViewController
//
final class BulkUpdatePriceViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak var saveButtonToBottom: NSLayoutConstraint!
    @IBOutlet weak var saveButton: ButtonActivityIndicator!

    private var viewModel: BulkUpdatePriceSettingsViewModel
    private var subscriptions = Set<AnyCancellable>()

    /// Tracking when the keyboard appears to keep the save button visible.
    ///
    private lazy var keyboardFrameObserver = KeyboardFrameObserver(onKeyboardFrameUpdate: { [weak self] frame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: frame)
    })

    init(viewModel: BulkUpdatePriceSettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTitleAndBackground()
        configureTableView()
        configureSaveButton()
        configureViewModel()
        keyboardFrameObserver.startObservingKeyboardFrame(sendInitialEvent: true)
    }

    /// Configures the title and appearance of the save button
    ///
    func configureSaveButton() {
        saveButton.applyPrimaryButtonStyle()
        // The transparency of the disable state makes content of the tableview appear to overlap with the button
        // So we give it a solid background color to match the tableView
        saveButton.backgroundColor = .listBackground
        saveButton.setTitle(Localization.saveButtonTitle, for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }

    /// Configures the screen title and background
    ///
    private func configureTitleAndBackground() {
        title = viewModel.screenTitle()
        view.backgroundColor = .listBackground
    }

    /// Setup receiving updates for data changes from the view model
    ///
    private func configureViewModel() {
        viewModel.$saveButtonState.sink { [weak self] state in
            self?.saveButton.isEnabled = state == .enabled

            if state == .loading {
                self?.saveButton.showActivityIndicator()
            } else {
                self?.saveButton.hideActivityIndicator()
            }
        }.store(in: &subscriptions)
    }

    /// Configures the table view: registers Nibs & setup dataSource
    ///
    private func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewCells()

        tableView.dataSource = self
    }

    private func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Called when the save button is tapped to update the price for all variations
    ///
    @objc private func saveButtonTapped() {
        // Dismiss the keyboard before triggering the update
        view.endEditing(true)
        viewModel.saveButtonTapped()
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension BulkUpdatePriceViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footer
    }
}

// MARK: - Cell configuration
//
private extension BulkUpdatePriceViewController {
    /// Configures a cell
    ///
    func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
        switch cell {
        case let cell as UnitInputTableViewCell:
            let cellViewModel = UnitInputViewModel.createBulkPriceViewModel(using: ServiceLocator.currencySettings) { [weak self] value in
                self?.viewModel.handlePriceChange(value)
            }
            cell.selectionStyle = .none
            cell.configure(viewModel: cellViewModel)
        default:
            fatalError("Unidentified bulk update row type")
            break
        }
    }
}

// MARK: - Methods for handling the [dis]appearance of the keyboard
//
extension BulkUpdatePriceViewController {
    private func handleKeyboardFrameUpdate(keyboardFrame: CGRect) {
        let keyboardHeight = keyboardFrame.height
        // Home Indicator safe area height is included in the keyboardHeight
        // and since our save button constraint is with the bottom safe are we do not want to add it two times
        let bottomInset = keyboardHeight > 0 ? keyboardHeight - view.safeAreaInsets.bottom : keyboardHeight

        saveButtonToBottom?.constant = bottomInset + Constants.saveButtonToBottomInset
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }
}

extension BulkUpdatePriceViewController {

    struct Section: Equatable {
        let footer: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case price

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .price:
                return UnitInputTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension BulkUpdatePriceViewController {
    enum Localization {
        static let saveButtonTitle = NSLocalizedString("Save", comment: "Button title that save the price selection for bulk variation update")
    }
}

private struct Constants {
    /// THe distance of the save button from the bottom
    static let saveButtonToBottomInset = 16.0
}
