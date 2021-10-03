import Combine
import Yosemite
import UIKit

/// Allows the user to select a paper size and print a shipping label given the selected paper size.
/// Informational links are displayed for printing instructions and paper size options.
final class PrintShippingLabelViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!

    /// Reprint button: Used to pin button to bottom of screen (below the table) when reprinting an existing label
    ///
    @IBOutlet weak var reprintButton: UIButton!

    private let viewModel: PrintShippingLabelViewModel
    private var rows: [Row] = []

    private var selectedPaperSize: ShippingLabelPaperSize?

    private var cancellables = Set<AnyCancellable>()

    /// Type of print action offered: printing a new label or reprinting an existing label
    private var printType: PrintShippingLabelCoordinator.PrintType

    /// Closure to be executed when an action is triggered.
    ///
    var onAction: ((ActionType) -> Void)?

    init(shippingLabels: [ShippingLabel], printType: PrintShippingLabelCoordinator.PrintType) {
        self.viewModel = PrintShippingLabelViewModel(shippingLabels: shippingLabels)
        self.printType = printType
        super.init(nibName: nil, bundle: nil)
        self.rows = rowsToDisplay()

        // Select the first paper size option available
        viewModel.updateSelectedPaperSize(viewModel.paperSizeOptions.first)
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
        /// Called when the "Save for Later" button is selected.
        case saveLabelForLater
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

    func saveLabelForLater() {
        onAction?(.saveLabelForLater)
    }
}

// MARK: Configuration
private extension PrintShippingLabelViewController {
    func configureNavigationBar() {
        navigationItem.title = Localization.navigationBarTitle(labelCount: viewModel.shippingLabels.count)
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
        guard printType == .reprint else {
            reprintButton.isHidden = true
            return
        }
        reprintButton.applyPrimaryButtonStyle()
        reprintButton.setTitle(Localization.printButtonTitle(labelCount: viewModel.shippingLabels.count), for: .normal)
        reprintButton.on(.touchUpInside) { [weak self] _ in
            self?.printShippingLabel()
        }
    }

    func observeSelectedPaperSize() {
        viewModel.loadShippingLabelSettingsForDefaultPaperSize()
        viewModel.$selectedPaperSize.removeDuplicates().sink { [weak self] paperSize in
            guard let self = self else { return }
            self.selectedPaperSize = paperSize
            self.tableView.reloadData()
            self.reprintButton.isEnabled = paperSize != nil
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
        case let cell as SpacerTableViewCell where row == .spacerBetweenHeaderCells:
            configureSpacerBetweenHeaderCells(cell: cell)
        case let cell as BasicTableViewCell where row == .headerText:
            configureHeaderText(cell: cell)
        case let cell as ImageTableViewCell where row == .headerImage:
            configureHeaderImage(cell: cell)
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
        case let cell as ButtonTableViewCell where row == .printButton:
            configurePrintButtonRow(cell: cell)
        case let cell as ButtonTableViewCell where row == .saveButton:
            configureSaveButton(cell: cell)
        default:
            break
        }
    }

    func rowsToDisplay() -> [Row] {
        var rows: [Row]
        switch printType {
        case .print:
            rows = [
                .spacerBetweenHeaderCells,
                .headerText,
                .spacerBetweenHeaderCells,
                .headerImage,
                .spacerBetweenHeaderCells,
                .paperSize,
                .spacerBetweenPaperSizeSelectorAndInfoLinks,
                .printButton,
                .saveButton,
                .paperSizeOptions,
                .printingInstructions
            ]
        case .reprint:
            rows = [
                .headerText,
                .infoText,
                .spacerBetweenInfoTextAndPaperSizeSelector,
                .paperSize,
                .spacerBetweenPaperSizeSelectorAndInfoLinks,
                .paperSizeOptions,
                .printingInstructions
            ]
        }
        return rows.map { $0 }
    }

    func configureHeaderText(cell: BasicTableViewCell) {
        switch printType {
        case .print:
            cell.textLabel?.text = Localization.printHeaderText(labelCount: viewModel.shippingLabels.count)
            cell.textLabel?.applyHeadlineStyle()
            cell.textLabel?.textAlignment = .center
        case .reprint:
            cell.textLabel?.text = Localization.reprintHeaderText
            cell.textLabel?.applyBodyStyle()
            cell.textLabel?.textAlignment = .natural
        }
        cell.textLabel?.numberOfLines = 0
        cell.hideSeparator()
    }

    func configureHeaderImage(cell: ImageTableViewCell) {
        cell.configure(image: .celebrationImage)
        cell.selectionStyle = .none
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

    func configureSpacerBetweenHeaderCells(cell: SpacerTableViewCell) {
        cell.configure(height: Constants.headerVerticalSpacing)
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

    func configurePrintButtonRow(cell: ButtonTableViewCell) {
        cell.configure(style: .primary,
                       title: Localization.printButtonTitle(labelCount: viewModel.shippingLabels.count),
                       topSpacing: Constants.buttonVerticalSpacing,
                       bottomSpacing: Constants.buttonVerticalSpacing) { [weak self] in
            self?.printShippingLabel()
        }
        cell.hideSeparator()
        cell.enableButton(selectedPaperSize != nil)
    }

    func configureSaveButton(cell: ButtonTableViewCell) {
        cell.configure(style: .secondary,
                       title: Localization.saveButtonTitle,
                       topSpacing: Constants.buttonVerticalSpacing,
                       bottomSpacing: Constants.buttonVerticalSpacing) { [weak self] in
            self?.saveLabelForLater()
        }
        cell.hideSeparator()
    }
}

private extension PrintShippingLabelViewController {
    enum Constants {
        static let verticalSpacingBetweenInfoTextAndPaperSizeSelector = CGFloat(8)
        static let verticalSpacingBetweenPaperSizeSelectorAndInfoLinks = CGFloat(8)
        static let buttonVerticalSpacing = CGFloat(8)
        static let headerVerticalSpacing = CGFloat(32)
    }

    enum Localization {
        static func navigationBarTitle(labelCount: Int) -> String {
            if labelCount == 1 {
                return NSLocalizedString("Print Shipping Label",
                                         comment: "Navigation bar title to print a shipping label")
            } else {
                return NSLocalizedString("Print Shipping Labels",
                                         comment: "Navigation bar title to print multiple shipping labels")
            }
        }
        static func printButtonTitle(labelCount: Int) -> String {
            if labelCount == 1 {
                return NSLocalizedString("Print Shipping Label",
                                         comment: "Button title to generate a shipping label document for printing")
            } else {
                return NSLocalizedString("Print Shipping Labels",
                                         comment: "Button title to generate a document with multiple shipping labels for printing")
            }
        }
        static let saveButtonTitle = NSLocalizedString("Save for Later",
                                                          comment: "Button title to save a shipping label to print later")
        static let paperSizeSelectorTitle = NSLocalizedString("Paper Size", comment: "Title of the paper size selector row for printing a shipping label")
        static func printHeaderText(labelCount: Int) -> String {
            if labelCount == 1 {
                return NSLocalizedString("Shipping label purchased!", comment: "Header text when printing a newly purchased shipping label")
            } else {
                return NSLocalizedString("Shipping labels purchased!", comment: "Header text when printing multiple newly purchased shipping labels")
            }
        }
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
        case spacerBetweenHeaderCells
        case headerText
        case headerImage
        case infoText
        case spacerBetweenInfoTextAndPaperSizeSelector
        case paperSize
        case spacerBetweenPaperSizeSelectorAndInfoLinks
        case paperSizeOptions
        case printingInstructions
        case printButton
        case saveButton

        var type: UITableViewCell.Type {
            switch self {
            case .headerText:
                return BasicTableViewCell.self
            case .headerImage:
                return ImageTableViewCell.self
            case .infoText:
                return ImageAndTitleAndTextTableViewCell.self
            case .spacerBetweenInfoTextAndPaperSizeSelector, .spacerBetweenPaperSizeSelectorAndInfoLinks, .spacerBetweenHeaderCells:
                return SpacerTableViewCell.self
            case .paperSize:
                return TitleAndValueTableViewCell.self
            case .paperSizeOptions, .printingInstructions:
                return ImageAndTitleAndTextTableViewCell.self
            case .printButton, .saveButton:
                return ButtonTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            type.reuseIdentifier
        }
    }
}
