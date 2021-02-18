import UIKit
import Yosemite

final class ShippingLabelFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ShippingLabelFormViewModel

    /// Init
    ///
    init(order: Order) {
        viewModel = ShippingLabelFormViewModel(originAddress: nil, destinationAddress: order.shippingAddress)
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
private extension ShippingLabelFormViewController {

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
        for row in RowType.allCases {
            tableView.registerNib(for: row.type)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ShippingLabelFormViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.type.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - Cell configuration
//
private extension ShippingLabelFormViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shipFrom:
            configureShipFrom(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shipTo:
            configureShipTo(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .packageDetails:
            configurePackageDetails(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .shippingCarrierAndRates:
            configureShippingCarrierAndRates(cell: cell, row: row)
        case let cell as ShippingLabelFormStepTableViewCell where row.type == .paymentMethod:
            configurePaymentMethod(cell: cell, row: row)
        default:
            fatalError("Cannot instantiate \(cell) with row \(row.type)")
            break
        }
    }

    func configureShipFrom(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .shippingImage,
                       title: Localization.shipFromCellTitle,
                       body: "To be implemented",
                       buttonTitle: Localization.continueButtonInCells) { [weak self] in
            let shippingLabelAddress = self?.viewModel.originAddress
            let shippingAddressValidationVC = ShippingLabelAddressFormViewController(type: .origin, address: shippingLabelAddress)
            self?.navigationController?.pushViewController(shippingAddressValidationVC, animated: true)
        }
    }

    func configureShipTo(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .houseOutlinedImage,
                       title: Localization.shipToCellTitle,
                       body: "To be implemented",
                       buttonTitle: Localization.continueButtonInCells) { [weak self] in
            let shippingLabelAddress = self?.viewModel.destinationAddress
            let shippingAddressValidationVC = ShippingLabelAddressFormViewController(type: .destination, address: shippingLabelAddress)
            self?.navigationController?.pushViewController(shippingAddressValidationVC, animated: true)
        }
    }

    func configurePackageDetails(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .productPlaceholderImage,
                       title: Localization.packageDetailsCellTitle,
                       body: "To be implemented",
                       buttonTitle: Localization.continueButtonInCells) {

        }
    }

    func configureShippingCarrierAndRates(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .priceImage,
                       title: Localization.shippingCarrierAndRatesCellTitle,
                       body: "To be implemented",
                       buttonTitle: Localization.continueButtonInCells) {

        }
    }

    func configurePaymentMethod(cell: ShippingLabelFormStepTableViewCell, row: Row) {
        cell.configure(state: row.cellState,
                       icon: .creditCardImage,
                       title: Localization.paymentMethodCellTitle,
                       body: "To be implemented",
                       buttonTitle: Localization.continueButtonInCells) {

        }
    }

}

extension ShippingLabelFormViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    struct Row: Equatable {
        let type: RowType
        let dataState: DataState
        let displayMode: DisplayMode

        fileprivate var cellState: ShippingLabelFormStepTableViewCell.State {
            if dataState == .validated && displayMode == .editable {
                return .enabled
            }
            else if dataState == .pending && displayMode == .editable {
                return .continue
            }
            return .disabled
        }
    }

    /// Each row has a data state
    enum DataState {
        /// the data are validated
        case validated

        /// the data still need to be validated
        case pending
    }

    /// Each row has a UI state
    enum DisplayMode {
        /// the row is not greyed out and is available for edit (a disclosure indicator is shown in the accessory view) and
        /// "Continue" CTA is shown to edit the row details
        case editable

        /// the row is greyed out
        case disabled
    }

    enum RowType: CaseIterable {
        case shipFrom
        case shipTo
        case packageDetails
        case shippingCarrierAndRates
        case paymentMethod

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .shipFrom, .shipTo, .packageDetails, .shippingCarrierAndRates, .paymentMethod:
                return ShippingLabelFormStepTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension ShippingLabelFormViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Create Shipping Label", comment: "Create Shipping Label form navigation title")
        static let shipFromCellTitle = NSLocalizedString("Ship from", comment: "Title of the cell Ship from inside Create Shipping Label form")
        static let shipToCellTitle = NSLocalizedString("Ship to", comment: "Title of the cell Ship From inside Create Shipping Label form")
        static let packageDetailsCellTitle = NSLocalizedString("Package Details",
                                                               comment: "Title of the cell Package Details inside Create Shipping Label form")
        static let shippingCarrierAndRatesCellTitle = NSLocalizedString("Shipping Carrier and Rates",
                                                                        comment: "Title of the cell Shipping Carrier inside Create Shipping Label form")
        static let paymentMethodCellTitle = NSLocalizedString("Payment Method",
                                                              comment: "Title of the cell Payment Method inside Create Shipping Label form")
        static let continueButtonInCells = NSLocalizedString("Continue",
                                                             comment: "Continue button inside every cell inside Create Shipping Label form")
    }
}
