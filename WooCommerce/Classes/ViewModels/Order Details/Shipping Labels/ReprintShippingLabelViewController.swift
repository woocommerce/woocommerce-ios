import Combine
import Yosemite
import UIKit

/// Allows the user to select a paper size and reprint a shipping label given the selected paper size.
/// Informational links are displayed for printing instructions and paper size options.
final class ReprintShippingLabelViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var reprintButton: UIButton!

    private let viewModel: ReprintShippingLabelViewModel
    private let rows: [Row]

    private var selectedPaperSize: ShippingLabelPaperSize?

    private var cancellables = Set<AnyCancellable>()

    init(shippingLabel: ShippingLabel) {
        self.viewModel = ReprintShippingLabelViewModel(shippingLabel: shippingLabel)
        self.rows = [.headerText, .infoText,
                     .spacerBetweenInfoTextAndPaperSizeSelector, .paperSize, .spacerBetweenPaperSizeSelectorAndInfoLinks,
                     .paperSizeOptions, .printingInstructions]
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cancellables.forEach {
            $0.cancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTableView()
        configureReprintButton()
        observeSelectedPaperSize()
    }
}

// MARK: Action Handling
private extension ReprintShippingLabelViewController {
    func reprintShippingLabel() {
        // TODO-2169: reprint action
    }
}

// MARK: Configuration
private extension ReprintShippingLabelViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle
    }

    func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        registerTableViewCells()

        tableView.removeLastCellSeparator()
        tableView.backgroundColor = .basicBackground
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    func configureReprintButton() {
        reprintButton.applyPrimaryButtonStyle()
        reprintButton.setTitle(Localization.reprintButtonTitle, for: .normal)
        reprintButton.on(.touchUpInside) { [weak self] _ in
            self?.reprintShippingLabel()
        }
    }

    func observeSelectedPaperSize() {
        viewModel.loadShippingLabelSettingsForDefaultPaperSize()
        viewModel.$selectedPaperSize.sink { [weak self] paperSize in
            guard let self = self else { return }
            self.selectedPaperSize = paperSize
            self.tableView.reloadData()
            self.reprintButton.isEnabled = paperSize != nil
        }.store(in: &cancellables)
    }
}

// MARK: UITableViewDataSource
extension ReprintShippingLabelViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = rows[safe: indexPath.row] else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row)
        return cell
    }
}

// MARK: UITableViewDelegate
extension ReprintShippingLabelViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let row = rows[safe: indexPath.row] else {
            return
        }

        switch row {
        case .paperSize:
            // TODO-2169: Navigate to paper size selector
            break
        case .paperSizeOptions:
            // TODO-2169: Present paper size options modal
            break
        case .printingInstructions:
            // TODO-2169: Present printing instructions modal
            break
        default:
            return
        }
    }
}

// MARK: Cell configuration
private extension ReprintShippingLabelViewController {
    func configure(_ cell: UITableViewCell, for row: Row) {
        switch cell {
        case let cell as BasicTableViewCell where row == .headerText:
            configureHeaderText(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .infoText:
            configureInfoText(cell: cell)
        case let cell as SettingTitleAndValueTableViewCell where row == .paperSize:
            configurePaperSize(cell: cell)
        case let cell as SpacerTableViewCell where row == .spacerBetweenInfoTextAndPaperSizeSelector:
            configureSpacerBetweenInfoTextAndPaperSizeSelector(cell: cell)
        case let cell as SpacerTableViewCell where row == .spacerBetweenPaperSizeSelectorAndInfoLinks:
            configureSpacerBetweenPaperSizeSelectorAndInfoLinks(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .paperSizeOptions:
            configurePaperSizeOptions(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .printingInstructions:
            configurePrintingInstructions(cell: cell)
        default:
            break
        }
    }

    func configureHeaderText(cell: BasicTableViewCell) {
        cell.textLabel?.text = Localization.headerText
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.applyBodyStyle()
        cell.hideSeparator()
    }

    func configureInfoText(cell: TopLeftImageTableViewCell) {
        cell.imageView?.image = .infoOutlineImage
        cell.imageView?.tintColor = .systemColor(.secondaryLabel)
        cell.textLabel?.textColor = .systemColor(.secondaryLabel)
        cell.textLabel?.text = Localization.infoText
        cell.apply(style: .body)
        cell.hideSeparator()
    }

    func configurePaperSize(cell: SettingTitleAndValueTableViewCell) {
        cell.updateUI(title: Localization.paperSizeSelectorTitle, value: selectedPaperSize?.description)
        cell.accessoryType = .disclosureIndicator
    }

    func configureSpacerBetweenInfoTextAndPaperSizeSelector(cell: SpacerTableViewCell) {
        cell.configure(height: Constants.verticalSpacingBetweenInfoTextAndPaperSizeSelector)
    }

    func configureSpacerBetweenPaperSizeSelectorAndInfoLinks(cell: SpacerTableViewCell) {
        cell.configure(height: Constants.verticalSpacingBetweenPaperSizeSelectorAndInfoLinks)
    }

    func configurePaperSizeOptions(cell: TopLeftImageTableViewCell) {
        cell.imageView?.image = .pagesFootnoteImage
        cell.textLabel?.text = Localization.paperSizeOptionsButtonTitle
        configureCommonStylesForInfoLinkCell(cell)
    }

    func configurePrintingInstructions(cell: TopLeftImageTableViewCell) {
        cell.imageView?.image = .infoOutlineFootnoteImage
        cell.textLabel?.text = Localization.printingInstructionsButtonTitle
        configureCommonStylesForInfoLinkCell(cell)
    }

    func configureCommonStylesForInfoLinkCell(_ cell: TopLeftImageTableViewCell) {
        cell.apply(style: .footnote)
        cell.imageView?.tintColor = .systemColor(.secondaryLabel)
        cell.textLabel?.textColor = .systemColor(.secondaryLabel)
        cell.hideSeparator()
        cell.selectionStyle = .default
    }
}

private extension ReprintShippingLabelViewController {
    enum Constants {
        static let verticalSpacingBetweenInfoTextAndPaperSizeSelector = CGFloat(8)
        static let verticalSpacingBetweenPaperSizeSelectorAndInfoLinks = CGFloat(8)
    }

    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Reprint Shipping Label",
                                                          comment: "Navigation bar title to reprint a shipping label")
        static let reprintButtonTitle = NSLocalizedString("Print Shipping Label",
                                                          comment: "Button title to generate a shipping label document for printing")
        static let paperSizeSelectorTitle = NSLocalizedString("Paper Size", comment: "Title of the paper size selector row for reprinting a shipping label")
        static let headerText = NSLocalizedString(
            "If there was a printing error when you purchased the label, you can print it again.",
            comment: "Header text when reprinting a shipping label")
        static let infoText = NSLocalizedString(
            "If you already used the label in a package, printing and using it again is a violation of our terms of service",
            comment: "Info text when reprinting a shipping label")
        static let paperSizeOptionsButtonTitle = NSLocalizedString("See layout and paper sizes options", comment: "Link title to see all paper size options")
        static let printingInstructionsButtonTitle = NSLocalizedString("Don’t know how to print from your device?",
                                                                       comment: "Link title to see instructions for printing a shipping label on an iOS device")
    }
}

private extension ReprintShippingLabelViewController {
    enum Row: CaseIterable {
        case headerText
        case infoText
        case spacerBetweenInfoTextAndPaperSizeSelector
        case paperSize
        case spacerBetweenPaperSizeSelectorAndInfoLinks
        case paperSizeOptions
        case printingInstructions

        var type: UITableViewCell.Type {
            switch self {
            case .headerText:
                return BasicTableViewCell.self
            case .infoText:
                return TopLeftImageTableViewCell.self
            case .spacerBetweenInfoTextAndPaperSizeSelector, .spacerBetweenPaperSizeSelectorAndInfoLinks:
                return SpacerTableViewCell.self
            case .paperSize:
                return SettingTitleAndValueTableViewCell.self
            case .paperSizeOptions, .printingInstructions:
                return TopLeftImageTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            type.reuseIdentifier
        }
    }
}
