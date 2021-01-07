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

    /// Closure to be executed when an action is triggered.
    ///
    var onAction: ((ActionType) -> Void)?

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

extension ReprintShippingLabelViewController {
    /// Actions that can be triggered from the reprint UI.
    enum ActionType {
        /// Called when the paper size row is selected.
        case showPaperSizeSelector(paperSizeOptions: [ShippingLabelPaperSize],
                                   selectedPaperSize: ShippingLabelPaperSize?,
                                   onSelection: (ShippingLabelPaperSize?) -> Void)
        /// Called when the Reprint CTA is tapped.
        case reprint(paperSize: ShippingLabelPaperSize)
        /// Called when the "layout and paper size options" row is selected.
        case presentPaperSizeOptions
        /// Called when the printing instructions row is selected.
        case presentPrintingInstructions
    }
}

// MARK: Action Handling
private extension ReprintShippingLabelViewController {
    func reprintShippingLabel() {
        guard let selectedPaperSize = selectedPaperSize else {
            return
        }
        onAction?(.reprint(paperSize: selectedPaperSize))
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
        viewModel.$selectedPaperSize.removeDuplicates().sink { [weak self] paperSize in
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
private extension ReprintShippingLabelViewController {
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

    func configureHeaderText(cell: BasicTableViewCell) {
        cell.textLabel?.text = Localization.headerText
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.applyBodyStyle()
        cell.hideSeparator()
    }

    func configureInfoText(cell: ImageAndTitleAndTextTableViewCell) {
        cell.update(with: .imageAndTitleOnly(fontStyle: .body),
                    data: .init(title: Localization.infoText,
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
