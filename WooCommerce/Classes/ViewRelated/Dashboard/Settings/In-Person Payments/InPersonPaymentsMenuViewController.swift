import UIKit
import SwiftUI
import Yosemite

final class InPersonPaymentsMenuViewController: UITableViewController {
    private let plugin: CardPresentPaymentsPlugins
    private var rows = [Row]()
    private let configurationLoader: CardPresentConfigurationLoader

    init(plugin: CardPresentPaymentsPlugins) {
        self.plugin = plugin
        configurationLoader = CardPresentConfigurationLoader()
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureRows()
        configureTableView()
        registerTableViewCells()
    }
}

// MARK: - View configuration
//
private extension InPersonPaymentsMenuViewController {

    func configureRows() {
        rows = [
            .orderCardReader,
            .manageCardReader
        ] + readerManualRows()
    }

    func readerManualRows() -> [Row] {
        configurationLoader.configuration.supportedReaders.map { readerType in
            switch readerType {
            case .chipper:
                return .bbposChipper2XBTManual
            case .stripeM2:
                return .stripeM2Manual
            case .wisepad3:
                return .wisepad3Manual
            case .other:
                preconditionFailure("Unknown card reader type was present in the supported readers list. This should not be possible")
            }
        }
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as LeftImageTableViewCell where row == .orderCardReader:
            configureOrderCardReader(cell: cell)
        case let cell as LeftImageTableViewCell where row == .manageCardReader:
            configureManageCardReader(cell: cell)
        case let cell as LeftImageTableViewCell where row == .bbposChipper2XBTManual:
            configureChipper2XManual(cell: cell)
        case let cell as LeftImageTableViewCell where row == .stripeM2Manual:
            configureStripeM2Manual(cell: cell)
        case let cell as LeftImageTableViewCell where row == .wisepad3Manual:
            configureWisepad3Manual(cell: cell)
        default:
            fatalError()
        }
    }

    func configureOrderCardReader(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .shoppingCartIcon, text: Localization.orderCardReader)
    }

    func configureManageCardReader(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .creditCardIcon, text: Localization.manageCardReader)
    }

    func configureChipper2XManual(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .cardReaderManualIcon, text: Localization.chipperCardReaderManual)
    }

    func configureStripeM2Manual(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .cardReaderManualIcon, text: Localization.stripeM2CardReaderManual)
    }

    func configureWisepad3Manual(cell: LeftImageTableViewCell) {
        cell.imageView?.tintColor = .text
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.configure(image: .cardReaderManualIcon, text: Localization.wisepad3CardReaderManual)
    }
}

// MARK: - Convenience methods
//
private extension InPersonPaymentsMenuViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        rows[indexPath.row]
    }
}

// MARK: - Actions
//
extension InPersonPaymentsMenuViewController {
    func orderCardReaderWasPressed() {
        WebviewHelper.launch(configurationLoader.configuration.purchaseCardReaderUrl(for: plugin), with: self)
    }

    func manageCardReaderWasPressed() {
        ServiceLocator.analytics.track(.settingsCardReadersTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: CardReaderSettingsPresentingViewController.self) else {
            fatalError("Cannot instantiate `CardReaderSettingsPresentingViewController` from Dashboard storyboard")
        }

        let viewModelsAndViews = CardReaderSettingsViewModelsOrderedList()
        viewController.configure(viewModelsAndViews: viewModelsAndViews)
        show(viewController, sender: self)
    }

    func bbposChipper2XBTManualWasPressed() {
            WebviewHelper.launch(Constants.bbposChipper2XBTManualURL, with: self)
    }

    func stripeM2ManualWasPressed() {
        WebviewHelper.launch(Constants.stripeM2ManualURL, with: self)
    }

    func wisepad3ManualWasPressed() {
        WebviewHelper.launch(Constants.wisepad3ManualURL, with: self)
    }
}

// MARK: - UITableViewDataSource
extension InPersonPaymentsMenuViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate
//
extension InPersonPaymentsMenuViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // listed in the order they are displayed
        switch rowAtIndexPath(indexPath) {
        case .orderCardReader:
            orderCardReaderWasPressed()
        case .manageCardReader:
            manageCardReaderWasPressed()
        case .bbposChipper2XBTManual:
            bbposChipper2XBTManualWasPressed()
        case .stripeM2Manual:
            stripeM2ManualWasPressed()
        case .wisepad3Manual:
            wisepad3ManualWasPressed()
        }
    }
}

// MARK: - Localizations
//
private extension InPersonPaymentsMenuViewController {
    enum Localization {
        static let orderCardReader = NSLocalizedString(
            "Order card reader",
            comment: "Navigates to Card Reader ordering screen"
        )

        static let manageCardReader = NSLocalizedString(
            "Manage card reader",
            comment: "Navigates to Card Reader management screen"
        )

        static let chipperCardReaderManual = NSLocalizedString(
            "Chipper 2X card reader manual",
            comment: "Navigates to Chipper Card Reader manual"
        )

        static let stripeM2CardReaderManual = NSLocalizedString(
            "Stripe M2 card reader manual",
            comment: "Navigates to Stripe M2 Card Reader manual"
        )

        static let wisepad3CardReaderManual = NSLocalizedString(
            "WisePad 3 card reader manual",
            comment: "Navigates to WisePad 3 Card Reader manual"
        )
    }
}

private enum Row: CaseIterable {
    case orderCardReader
    case manageCardReader
    case bbposChipper2XBTManual
    case stripeM2Manual
    case wisepad3Manual

    var type: UITableViewCell.Type {
        LeftImageTableViewCell.self
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

private enum Constants {
    static let bbposChipper2XBTManualURL = URL(string: "https://developer.bbpos.com/quick_start_guide/Chipper%202X%20BT%20Quick%20Start%20Guide.pdf")!
    static let stripeM2ManualURL = URL(string: "https://stripe.com/files/docs/terminal/m2_product_sheet.pdf")!
    static let wisepad3ManualURL = URL(string: "https://stripe.com/files/docs/terminal/wp3_product_sheet.pdf")!
}

// MARK: - SwiftUI compatibility
//

/// SwiftUI wrapper for CardReaderSettingsPresentingViewController
///
struct InPersonPaymentsMenu: UIViewControllerRepresentable {
    let plugin: CardPresentPaymentsPlugins

    func makeUIViewController(context: Context) -> some UIViewController {
        InPersonPaymentsMenuViewController(plugin: plugin)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
