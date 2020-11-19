import UIKit
import Yosemite

final class LinkedProductsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: LinkedProductsViewModel
    // Completion callback
    //
    typealias Completion = (_ upsellIDs: [Int64],
                            _ crossSellIDs: [Int64],
                            _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    /// Init
    ///
    init(product: ProductFormDataModel, completion: @escaping Completion) {
        viewModel = LinkedProductsViewModel(product: product)
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

// MARK: - View Configuration
//
private extension LinkedProductsViewController {

    func configureNavigationBar() {
        title = Localization.titleView

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeUpdating))
        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension LinkedProductsViewController: UITableViewDataSource {

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

// MARK: - UITableViewDelegate Conformance
//
extension LinkedProductsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let row = rowAtIndexPath(indexPath)
//
//        switch row {
//        case .scheduleSaleFrom:
//            viewModel.didTapScheduleSaleFromRow()
//            refreshViewContent()
//        case .scheduleSaleTo:
//            viewModel.didTapScheduleSaleToRow()
//            refreshViewContent()
//        case .removeSaleTo:
//            viewModel.handleSaleEndDateChange(nil)
//            refreshViewContent()
//        case .taxStatus:
//            let command = ProductTaxStatusListSelectorCommand(selected: viewModel.taxStatus)
//            let listSelectorViewController = ListSelectorViewController(command: command) { [weak self] selected in
//                                                                            if let selected = selected {
//                                                                                self?.viewModel.handleTaxStatusChange(selected)
//                                                                            }
//                                                                            self?.refreshViewContent()
//            }
//            navigationController?.pushViewController(listSelectorViewController, animated: true)
//        case .taxClass:
//            let dataSource = ProductTaxClassListSelectorDataSource(siteID: siteID, selected: viewModel.taxClass)
//            let navigationBarTitle = NSLocalizedString("Tax classes", comment: "Navigation bar title of the Product tax class selector screen")
//            let noResultsPlaceholderText = NSLocalizedString("No tax classes yet",
//            comment: "The text on the placeholder overlay when there are no tax classes on the Tax Class list picker")
//            let noResultsPlaceholderImage = UIImage.errorStateImage
//            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: navigationBarTitle,
//                                                                     noResultsPlaceholderText: noResultsPlaceholderText,
//                                                                     noResultsPlaceholderImage: noResultsPlaceholderImage,
//                                                                     noResultsPlaceholderImageTintColor: .gray(.shade20),
//                                                                     tableViewStyle: .grouped)
//            let selectorViewController =
//                PaginatedListSelectorViewController(viewProperties: viewProperties,
//                                                    dataSource: dataSource) { [weak self] selected in
//                                                        guard let self = self else {
//                                                            return
//                                                        }
//                                                        self.viewModel.handleTaxClassChange(selected)
//                                                        self.refreshViewContent()
//            }
//            navigationController?.pushViewController(selectorViewController, animated: true)
//        default:
//            break
//        }
    }
}

// MARK: - Cell configuration
//
private extension LinkedProductsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ImageAndTitleAndTextTableViewCell where row == .upsells:
            configureUpsells(cell: cell)
        case let cell as ImageAndTitleAndTextTableViewCell where row == .crossSells:
            configureCrossSells(cell: cell)
        case let cell as BasicTableViewCell where row == .upsellsProducts:
            configureUpsellsProducts(cell: cell)
        case let cell as BasicTableViewCell where row == .crossSellsProducts:
            configureCrossSellsProducts(cell: cell)
        case let cell as BasicTableViewCell where row == .upsellsButton:
            configureUpsellsButton(cell: cell)
        case let cell as BasicTableViewCell where row == .crossSellsButton:
            configureCrossSellsButton(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureUpsells(cell: ImageAndTitleAndTextTableViewCell) {

    }

    func configureCrossSells(cell: ImageAndTitleAndTextTableViewCell) {

    }

    func configureUpsellsProducts(cell: BasicTableViewCell) {

    }

    func configureCrossSellsProducts(cell: BasicTableViewCell) {

    }

    func configureUpsellsButton(cell: BasicTableViewCell) {

    }

    func configureCrossSellsButton(cell: BasicTableViewCell) {

    }
}

// MARK: - Navigation actions handling
//
extension LinkedProductsViewController {

    override func shouldPopOnBackButton() -> Bool {
        if viewModel.hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeUpdating() {
//        viewModel.completeUpdating(
//            onCompletion: { [weak self] (regularPrice, salePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass, hasUnsavedChanges) in
//                self?.onCompletion(regularPrice, salePrice, dateOnSaleStart, dateOnSaleEnd, taxStatus, taxClass, hasUnsavedChanges)
//            }, onError: { [weak self] error in
//                switch error {
//                case .salePriceWithoutRegularPrice:
//                    self?.displaySalePriceWithoutRegularPriceErrorNotice()
//                case .salePriceHigherThanRegularPrice:
//                    self?.displaySalePriceErrorNotice()
//                }
//        })
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

extension LinkedProductsViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case upsells
        case upsellsProducts
        case upsellsButton

        case crossSells
        case crossSellsProducts
        case crossSellsButton

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .upsells, .crossSells:
                return ImageAndTitleAndTextTableViewCell.self
            case .upsellsProducts, .crossSellsProducts:
                return BasicTableViewCell.self
            case .upsellsButton, .crossSellsButton:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension LinkedProductsViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Linked Products", comment: "Linked Products Settings navigation title")
    }
}
