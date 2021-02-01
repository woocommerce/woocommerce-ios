import UIKit
import Yosemite

class CreateShippingLabelFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: CreateShippingLabelFormViewModel

    /// Init
    ///
    init(order: Order) {
        viewModel = CreateShippingLabelFormViewModel(order: order)
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
private extension CreateShippingLabelFormViewController {

    func configureNavigationBar() {
        title = Localization.titleView
        removeNavigationBackBarButtonText()
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
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension CreateShippingLabelFormViewController: UITableViewDataSource {

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
private extension CreateShippingLabelFormViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .shipFrom:
            configureShipFrom(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureShipFrom(cell: BasicTableViewCell) {
        // TODO: to be implemented
    }
}

extension CreateShippingLabelFormViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case shipFrom
        case shipTo
        case packageDetails
        case shippingCarrierAndRates
        case paymentMethod

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .shipFrom, .shipTo, .packageDetails, .shippingCarrierAndRates, .paymentMethod:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension CreateShippingLabelFormViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Create Shipping Label", comment: "Create Shipping Label navigation title")
    }
}
