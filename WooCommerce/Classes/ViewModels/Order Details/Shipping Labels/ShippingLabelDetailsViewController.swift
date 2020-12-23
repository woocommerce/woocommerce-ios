import UIKit
import struct Yosemite.ShippingLabel

/// Displays a list of shipping label details like shipping addresses, carrier and rates, payment method.
final class ShippingLabelDetailsViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ShippingLabelDetailsViewModel
    private let rows: [Row]

    init(shippingLabel: ShippingLabel, currencyFormatter: CurrencyFormatter = .init(currencySettings: ServiceLocator.currencySettings)) {
        self.viewModel = ShippingLabelDetailsViewModel(shippingLabel: shippingLabel, currencyFormatter: currencyFormatter)
        self.rows = [
            .shipFrom,
            .shipTo,
            .packageDetails,
            .carrierAndRates,
            .paymentMethod
        ]
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTableView()
    }
}

extension ShippingLabelDetailsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row)
        return cell
    }

    private func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        rows[indexPath.row]
    }
}

private extension ShippingLabelDetailsViewController {
    func configureNavigationBar() {
        title = Localization.title
    }

    func configureTableView() {
        tableView.dataSource = self
        registerTableViewCells()
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .listBackground
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }
}

private extension ShippingLabelDetailsViewController {
    func configure(_ cell: UITableViewCell, for row: Row) {
        switch cell {
        case let cell as ImageAndTitleAndTextTableViewCell where row == .shipFrom:
            configureShipFrom(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .shipTo:
            configureShipTo(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .packageDetails:
            configurePackageDetails(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .carrierAndRates:
            configureCarrierAndRates(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .paymentMethod:
            configurePaymentMethod(cell: cell)
        default:
            break
        }
    }

    func configureShipFrom(cell: ImageAndTitleAndTextTableViewCell) {
        let cellViewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: Localization.shipFromTitle,
                                                                        text: viewModel.originAddress,
                                                                        image: .shippingImage,
                                                                        imageTintColor: Constants.cellImageColor,
                                                                        numberOfLinesForTitle: 0,
                                                                        numberOfLinesForText: 0,
                                                                        isActionable: false)
        cell.updateUI(viewModel: cellViewModel)
    }

    func configureShipTo(cell: ImageAndTitleAndTextTableViewCell) {
        let cellViewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: Localization.shipToTitle,
                                                                        text: viewModel.destinationAddress,
                                                                        image: .houseOutlinedImage,
                                                                        imageTintColor: Constants.cellImageColor,
                                                                        numberOfLinesForTitle: 0,
                                                                        numberOfLinesForText: 0,
                                                                        isActionable: false)
        cell.updateUI(viewModel: cellViewModel)
    }

    func configurePackageDetails(cell: ImageAndTitleAndTextTableViewCell) {
        let cellViewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: Localization.packageDetailsTitle,
                                                                        text: viewModel.packageName,
                                                                        image: .productImage,
                                                                        imageTintColor: Constants.cellImageColor,
                                                                        numberOfLinesForTitle: 0,
                                                                        numberOfLinesForText: 0,
                                                                        isActionable: false)
        cell.updateUI(viewModel: cellViewModel)
    }

    func configureCarrierAndRates(cell: ImageAndTitleAndTextTableViewCell) {
        let cellViewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: Localization.carrierAndRatesTitle,
                                                                        text: viewModel.carrierAndRate,
                                                                        image: .priceImage,
                                                                        imageTintColor: Constants.cellImageColor,
                                                                        numberOfLinesForTitle: 0,
                                                                        numberOfLinesForText: 0,
                                                                        isActionable: false)
        cell.updateUI(viewModel: cellViewModel)
    }

    func configurePaymentMethod(cell: ImageAndTitleAndTextTableViewCell) {
        let cellViewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: Localization.paymentMethodTitle,
                                                                        text: viewModel.paymentMethod,
                                                                        image: .creditCardImage,
                                                                        imageTintColor: Constants.cellImageColor,
                                                                        numberOfLinesForTitle: 0,
                                                                        numberOfLinesForText: 0,
                                                                        isActionable: false)
        cell.updateUI(viewModel: cellViewModel)
    }
}

private extension ShippingLabelDetailsViewController {
    enum Row: CaseIterable {
        case shipFrom
        case shipTo
        case packageDetails
        case carrierAndRates
        case paymentMethod

        var type: UITableViewCell.Type {
            ImageAndTitleAndTextTableViewCell.self
        }

        var reuseIdentifier: String {
            type.reuseIdentifier
        }
    }
}

private extension ShippingLabelDetailsViewController {
    enum Localization {
        static let title = NSLocalizedString("Shipment Details", comment: "Navigation bar title of shipping label details")
        static let shipFromTitle = NSLocalizedString("Ship from", comment: "Title of origin address in shipping label details")
        static let shipToTitle = NSLocalizedString("Ship to", comment: "Title of destination address in shipping label details")
        static let packageDetailsTitle = NSLocalizedString("Package Details", comment: "Title of package details in shipping label details")
        static let carrierAndRatesTitle = NSLocalizedString("Shipping Carrier and Rates",
                                                            comment: "Title of shipping carrier and rates in shipping label details")
        static let paymentMethodTitle = NSLocalizedString("Payment Method", comment: "Title of payment method in shipping label details")
    }

    enum Constants {
        static let cellImageColor: UIColor = .textSubtle
    }
}
