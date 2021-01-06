import UIKit
import Yosemite

final class LinkedProductsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let product: ProductFormDataModel

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
        self.product = product
        viewModel = LinkedProductsViewModel(product: product)
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        ServiceLocator.analytics.track(.linkedProducts, withProperties: ["action": "shown"])
        configureNavigationBar()
        configureMainView()
        configureTableView()
        registerTableViewCells()
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
        case let cell as NumberOfLinkedProductsTableViewCell where row == .upsellsProducts:
            configureUpsellsProducts(cell: cell)
        case let cell as NumberOfLinkedProductsTableViewCell where row == .crossSellsProducts:
            configureCrossSellsProducts(cell: cell)
        case let cell as ButtonTableViewCell where row == .upsellsButton:
            configureUpsellsButton(cell: cell)
        case let cell as ButtonTableViewCell where row == .crossSellsButton:
            configureCrossSellsButton(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureUpsells(cell: ImageAndTitleAndTextTableViewCell) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: Localization.upsellsCellTitle,
                                                                    text: Localization.upsellsCellDescription,
                                                                    image: UIImage.arrowUp,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0,
                                                                    isActionable: false)
        cell.updateUI(viewModel: viewModel)
    }

    func configureCrossSells(cell: ImageAndTitleAndTextTableViewCell) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: Localization.crossSellsCellTitle,
                                                                    text: Localization.crossSellsCellDescription,
                                                                    image: UIImage.syncIcon,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0,
                                                                    isActionable: false)
        cell.updateUI(viewModel: viewModel)
    }

    func configureUpsellsProducts(cell: NumberOfLinkedProductsTableViewCell) {
        cell.configure(content: Localization.upsellAndCrossSellProducts(count: viewModel.upsellIDs.count))
    }

    func configureCrossSellsProducts(cell: NumberOfLinkedProductsTableViewCell) {
        cell.configure(content: Localization.upsellAndCrossSellProducts(count: viewModel.crossSellIDs.count))
    }

    func configureUpsellsButton(cell: ButtonTableViewCell) {
        guard let product = product as? EditableProductModel else {
            return
        }

        let viewConfiguration = LinkedProductsListSelectorViewController.ViewConfiguration(title: Localization.titleScreenAddUpsellProducts,
                                                                                           trackingContext: "upsells")

        let viewController = LinkedProductsListSelectorViewController(product: product.product,
                                                                      linkedProductIDs: viewModel.upsellIDs,
                                                                      viewConfiguration: viewConfiguration) { [weak self] upsellIDs in
            self?.viewModel.handleUpsellIDsChange(upsellIDs)
            self?.tableView.reloadData()
            self?.navigationController?.popViewController(animated: true)
        }


        let buttonTitle = Localization.buttonTitle(count: viewModel.upsellIDs.count)
        cell.configure(style: .secondary, title: buttonTitle) { [weak self] in
            self?.show(viewController, sender: self)
        }
    }

    func configureCrossSellsButton(cell: ButtonTableViewCell) {
        guard let product = product as? EditableProductModel else {
            return
        }

        let viewConfiguration = LinkedProductsListSelectorViewController.ViewConfiguration(title: Localization.titleScreenAddUpsellProducts,
                                                                                           trackingContext: "cross_sells")

        let viewController = LinkedProductsListSelectorViewController(product: product.product,
                                                                      linkedProductIDs: viewModel.crossSellIDs,
                                                                      viewConfiguration: viewConfiguration) { [weak self] crossSellIDs in
            self?.viewModel.handleCrossSellIDsChange(crossSellIDs)
            self?.tableView.reloadData()
            self?.navigationController?.popViewController(animated: true)
        }

        let buttonTitle = Localization.buttonTitle(count: viewModel.crossSellIDs.count)
        cell.configure(style: .secondary, title: buttonTitle) { [weak self] in
            self?.show(viewController, sender: self)
        }
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
        onCompletion(viewModel.upsellIDs, viewModel.crossSellIDs, viewModel.hasUnsavedChanges())
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
                return NumberOfLinkedProductsTableViewCell.self
            case .upsellsButton, .crossSellsButton:
                return ButtonTableViewCell.self
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
        static let upsellsCellTitle = NSLocalizedString("Upsells", comment: "Cell title for Upsells products in Linked Products Settings screen")
        static let upsellsCellDescription = NSLocalizedString("Products promoted instead of the currently viewed product (ie more profitable products)",
                                                              comment: "Cell description for Upsells products in Linked Products Settings screen")
        static let crossSellsCellTitle = NSLocalizedString("Cross-sells", comment: "Cell title for Cross-sells products in Linked Products Settings screen")
        static let crossSellsCellDescription = NSLocalizedString("Products promoted in the cart when current product is selected",
                                                                 comment: "Cell description for Cross-sells products in Linked Products Settings screen")

        static func upsellAndCrossSellProducts(count: Int) -> String {
            let format: String = {
                if count <= 1 {
                    return NSLocalizedString("%ld product",
                           comment: "Format for number of products added for upsell and cross sell numbers in linked products. Reads, `1 product`")
                } else {
                    return NSLocalizedString("%ld products",
                           comment: "Format for number of products added for upsell and cross sell numbers in linked products. Reads, `5 products`")
                }
            }()

            return String.localizedStringWithFormat(format, count)
        }

        static func buttonTitle(count: Int) -> String {
            return {
                if count == 0 {
                    return NSLocalizedString("Add Products",
                           comment: "Add Products button inside the Linked Products screen.")
                } else {
                    return NSLocalizedString("Edit Products",
                           comment: "Edit Products button inside the Linked Products screen.")
                }
            }()
        }

        static let titleScreenAddUpsellProducts = NSLocalizedString("Upsells Products",
                                                                    comment: "Navigation bar title for editing linked products for upsell products")
        static let titleScreenAddCrossSellProducts = NSLocalizedString("Cross-sells Products",
                                                                       comment: "Navigation bar title for editing linked products for cross-sell products")
    }
}
