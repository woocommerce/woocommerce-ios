import UIKit
import Yosemite
import Combine

final class PriceInputViewController: UIViewController {

    let tableView: UITableView = UITableView(frame: .zero, style: .grouped)

    private var viewModel: PriceInputViewModel
    private var subscriptions = Set<AnyCancellable>()

    init(viewModel: PriceInputViewModel) {
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
        configureViewModel()
    }
}

private extension PriceInputViewController {
    func configureTitleAndBackground() {
        title = viewModel.screenTitle()
        view.backgroundColor = .listBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelButtonTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Localization.bulkEditingApply,
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(applyButtonTapped))
    }

    func configureViewModel() {
        viewModel.$applyButtonEnabled
            .sink { [weak self] enabled in
                self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
            }.store(in: &subscriptions)
    }

    func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        view.pinSubviewToAllEdges(tableView)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        tableView.registerNib(for: UnitInputTableViewCell.self)

        tableView.dataSource = self
    }

    /// Called when the cancel button is tapped
    ///
    @objc func cancelButtonTapped() {
        viewModel.cancelButtonTapped()
    }

    /// Called when the save button is tapped to update the price for all products
    ///
    @objc func applyButtonTapped() {
        // Dismiss the keyboard before triggering the update
        view.endEditing(true)
        viewModel.applyButtonTapped()
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension PriceInputViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UnitInputTableViewCell.self.reuseIdentifier, for: indexPath)
        configure(cell, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.footerText
    }

    private func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
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

private extension PriceInputViewController {
    enum Localization {
        static let bulkEditingApply = NSLocalizedString("Apply", comment: "Title for the button to apply bulk editing changes to selected products.")
    }
}
