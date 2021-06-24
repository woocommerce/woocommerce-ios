import Combine
import Yosemite
import UIKit

/// Allows the user to select a paper size and print a shipping label given the selected paper size.
/// Informational links are displayed for printing instructions and paper size options.
final class PrintShippingLabelViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var printButton: UIButton!

    private let viewModel: PrintShippingLabelViewModel
    private var rows: [Row] = []

    private var selectedPaperSize: ShippingLabelPaperSize?

    private var cancellables = Set<AnyCancellable>()

    /// Type of print action offered: printing a new label or reprinting an existing label
    private var printType: PrintShippingLabelCoordinator.PrintType

    /// Closure to be executed when an action is triggered.
    ///
    var onAction: ((ActionType) -> Void)?

    init(shippingLabel: ShippingLabel, printType: PrintShippingLabelCoordinator.PrintType) {
        self.viewModel = PrintShippingLabelViewModel(shippingLabel: shippingLabel)
        self.printType = printType
        super.init(nibName: nil, bundle: nil)
        self.rows = rowsToDisplay()
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
        configurePrintButton()
        observeSelectedPaperSize()
    }
}

extension PrintShippingLabelViewController {
    /// Actions that can be triggered from the print UI.
    enum ActionType {
        /// Called when the paper size row is selected.
        case showPaperSizeSelector(paperSizeOptions: [ShippingLabelPaperSize],
                                   selectedPaperSize: ShippingLabelPaperSize?,
                                   onSelection: (ShippingLabelPaperSize?) -> Void)
        /// Called when the Print CTA is tapped.
        case print(paperSize: ShippingLabelPaperSize)
        /// Called when the "layout and paper size options" row is selected.
        case presentPaperSizeOptions
        /// Called when the printing instructions row is selected.
        case presentPrintingInstructions
    }
}

// MARK: Action Handling
private extension PrintShippingLabelViewController {
    func printShippingLabel() {
        guard let selectedPaperSize = selectedPaperSize else {
            return
        }
        onAction?(.print(paperSize: selectedPaperSize))
    }

    func showPaperSizeSelector() {
        onAction?(.showPaperSizeSelector(paperSizeOptions: viewModel.paperSizeOptions,
                                         selectedPaperSize: selectedPaperSize,
                                         onSelection: { [weak self] paperSize in
                                            self?.viewModel.updateSelectedPaperSize(paperSize)
                                         }))
    }

    func presentPaperSizeOptions() {
        onAction?(.presentPaperSizeOptions)
    }

    func presentPrintingInstructions() {
        onAction?(.presentPrintingInstructions)
    }
}

// MARK: Configuration
private extension PrintShippingLabelViewController {
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

    func configurePrintButton() {
        printButton.applyPrimaryButtonStyle()
        printButton.setTitle(Localization.printButtonTitle, for: .normal)
        printButton.on(.touchUpInside) { [weak self] _ in
            self?.printShippingLabel()
        }
    }

    func observeSelectedPaperSize() {
        viewModel.loadShippingLabelSettingsForDefaultPaperSize()
        viewModel.$selectedPaperSize.removeDuplicates().sink { [weak self] paperSize in
            guard let self = self else { return }
            self.selectedPaperSize = paperSize
            self.tableView.reloadData()
            self.printButton.isEnabled = paperSize != nil
        }.store(in: &cancellables)
    }
}

// MARK: UITableViewDataSource
extension PrintShippingLabelViewController: UITableViewDataSource {
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
extension PrintShippingLabelViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let row = rows[safe: indexPath.row] else {
            return
        }

        switch row {
        case .paperSize:
            showPaperSizeSelector()
        case .paperSizeOptions:
            presentPaperSizeOptions()
        case .printingInstructions:
            presentPrintingInstructions()
        default:
            return
        }
    }
}

// MARK: Cell configuration
private extension PrintShippingLabelViewController {
    func configure(_ cell: UITableViewCell, for row: Row) {
        switch cell {
        case let cell as BasicTableViewCell where row == .headerText:
            configureHeaderText(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .infoText:
            configureInfoText(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .paperSize:
            configurePaperSize(cell: cell)
        case let cell as SpacerTableViewCell where row == .spacerBetweenInfoTextAndPaperSizeSelector:
            configureSpacerBetweenInfoTextAndPaperSizeSelector(cell: cell)
        case let cell as SpacerTableViewCell where row == .spacerBetweenPaperSizeSelectorAndInfoLinks:
            configureSpacerBetweenPaperSizeSelectorAndInfoLinks(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .paperSizeOptions:
            configurePaperSizeOptions(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .printingInstructions:
            configurePrintingInstructions(cell: cell)
        default:
            break
        }
    }

    func rowsToDisplay() -> [Row] {
        let shouldShowInfoText = printType == .reprint
        let rows: [Row?] = [
            .headerText,
            shouldShowInfoText ? .infoText : nil,
            .spacerBetweenInfoTextAndPaperSizeSelector,
            .paperSize,
            .spacerBetweenPaperSizeSelectorAndInfoLinks,
            .paperSizeOptions,
            .printingInstructions
        ]
        return rows.compactMap { $0 }
    }

    func configureHeaderText(cell: BasicTableViewCell) {
        switch printType {
        case .print:
            cell.textLabel?.text = Localization.printHeaderText
            cell.textLabel?.applyHeadlineStyle()
            cell.textLabel?.textAlignment = .center
        case .reprint:
            cell.textLabel?.text = Localization.reprintHeaderText
            cell.textLabel?.applyBodyStyle()
        }
        cell.textLabel?.numberOfLines = 0
        cell.hideSeparator()
    }

    func configureInfoText(cell: ImageAndTitleAndTextTableViewCell) {
        cell.update(with: .imageAndTitleOnly(fontStyle: .body),
                    data: .init(title: Localization.reprintInfoText,
                                textTintColor: .systemColor(.secondaryLabel),
                                image: .infoOutlineImage,
                                imageTintColor: .systemColor(.secondaryLabel),
                                numberOfLinesForTitle: 0,
                                isActionable: false,
                                showsSeparator: false))
    }

    func configurePaperSize(cell: TitleAndValueTableViewCell) {
        cell.updateUI(title: Localization.paperSizeSelectorTitle, value: selectedPaperSize?.description)
        cell.accessoryType = .disclosureIndicator
    }

    func configureSpacerBetweenInfoTextAndPaperSizeSelector(cell: SpacerTableViewCell) {
        cell.configure(height: Constants.verticalSpacingBetweenInfoTextAndPaperSizeSelector)
    }

    func configureSpacerBetweenPaperSizeSelectorAndInfoLinks(cell: SpacerTableViewCell) {
        cell.configure(height: Constants.verticalSpacingBetweenPaperSizeSelectorAndInfoLinks)
    }

    func configurePaperSizeOptions(cell: ImageAndTitleAndTextTableViewCell) {
        cell.update(with: .imageAndTitleOnly(fontStyle: .footnote),
                    data: .init(title: Localization.paperSizeOptionsButtonTitle,
                                textTintColor: .systemColor(.secondaryLabel),
                                image: .pagesFootnoteImage,
                                imageTintColor: .systemColor(.secondaryLabel),
                                numberOfLinesForTitle: 0,
                                isActionable: false,
                                showsSeparator: false))
        configureCommonStylesForInfoLinkCell(cell)
    }

    func configurePrintingInstructions(cell: ImageAndTitleAndTextTableViewCell) {
        cell.update(with: .imageAndTitleOnly(fontStyle: .footnote),
                    data: .init(title: Localization.printingInstructionsButtonTitle,
                                textTintColor: .systemColor(.secondaryLabel),
                                image: .infoOutlineFootnoteImage,
                                imageTintColor: .systemColor(.secondaryLabel),
                                numberOfLinesForTitle: 0,
                                isActionable: false,
                                showsSeparator: false))
        configureCommonStylesForInfoLinkCell(cell)
    }

    func configureCommonStylesForInfoLinkCell(_ cell: ImageAndTitleAndTextTableViewCell) {
        cell.selectionStyle = .default
    }
}

private extension PrintShippingLabelViewController {
    enum Constants {
        static let verticalSpacingBetweenInfoTextAndPaperSizeSelector = CGFloat(8)
        static let verticalSpacingBetweenPaperSizeSelectorAndInfoLinks = CGFloat(8)
    }

    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Print Shipping Label",
                                                          comment: "Navigation bar title to print a shipping label")
        static let printButtonTitle = NSLocalizedString("Print Shipping Label",
                                                          comment: "Button title to generate a shipping label document for printing")
        static let paperSizeSelectorTitle = NSLocalizedString("Paper Size", comment: "Title of the paper size selector row for printing a shipping label")
        static let printHeaderText = NSLocalizedString("Shipping label purchased!", comment: "Header text when printing a newly purchased shipping label")
        static let reprintHeaderText = NSLocalizedString(
            "If there was a printing error when you purchased the label, you can print it again.",
            comment: "Header text when reprinting a shipping label")
        static let reprintInfoText = NSLocalizedString(
            "If you already used the label in a package, printing and using it again is a violation of our terms of service",
            comment: "Info text when reprinting a shipping label")
        static let paperSizeOptionsButtonTitle = NSLocalizedString("See layout and paper sizes options", comment: "Link title to see all paper size options")
        static let printingInstructionsButtonTitle = NSLocalizedString("Don’t know how to print from your device?",
                                                                       comment: "Link title to see instructions for printing a shipping label on an iOS device")
    }
}

private extension PrintShippingLabelViewController {
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
                return ImageAndTitleAndTextTableViewCell.self
            case .spacerBetweenInfoTextAndPaperSizeSelector, .spacerBetweenPaperSizeSelectorAndInfoLinks:
                return SpacerTableViewCell.self
            case .paperSize:
                return TitleAndValueTableViewCell.self
            case .paperSizeOptions, .printingInstructions:
                return ImageAndTitleAndTextTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            type.reuseIdentifier
        }
    }
}
