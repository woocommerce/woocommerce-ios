import UIKit
import Yosemite

final class AttributePickerViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    private let viewModel: AttributePickerViewModel
    private let analytics: Analytics

    typealias Completion = (_ attributes: [ProductVariationAttribute]) -> Void
    private let onCompletion: Completion

    /// Init
    ///
    init(variationModel: EditableProductVariationModel, analytics: Analytics = ServiceLocator.analytics, onCompletion: @escaping Completion) {
        self.viewModel = .init(variationModel: variationModel)
        self.analytics = analytics
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        registerTableViewHeaderSections()
        registerTableViewCells()
        configureTableView()
        handleSwipeBackGesture()
    }
}

// MARK: - View Configuration
//
private extension AttributePickerViewController {

    func configureNavigationBar() {
        title = Localization.titleView
    }

    func updateDoneButton() {
        if viewModel.isChanged {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewHeaderSections() {
        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }

    func registerTableViewCells() {
        tableView.registerNib(for: TitleAndValueTableViewCell.self)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AttributePickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.attributes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(TitleAndValueTableViewCell.self, for: indexPath)
        configureAttribute(cell: cell, attribute: viewModel.attributes[safe: indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AttributePickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        presentAttributeOptions(for: viewModel.attributes[safe: indexPath.row])
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            assertionFailure("Could not find section header view for reuseIdentifier \(headerID)")
            return nil
        }

        headerView.leftText = Localization.headerAttributes
        headerView.rightText = nil

        return headerView
    }
}

// MARK: - Cell configuration
//
private extension AttributePickerViewController {
    func configureAttribute(cell: TitleAndValueTableViewCell, attribute: ProductAttribute?) {
        guard let attribute = attribute else {
            return
        }

        let optionValue = viewModel.selectedOption(for: attribute)?.option ?? Localization.anyOption

        cell.updateUI(title: attribute.name, value: optionValue)
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: Back Navigation
extension AttributePickerViewController {

    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.isChanged else {
            return true
        }

        presentBackNavigationActionSheet()
        return false
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }
}

// MARK: - Navigation actions handling
//
private extension AttributePickerViewController {

    @objc func doneButtonPressed() {
        onCompletion(viewModel.resultAttributes)
        analytics.track(event: WooAnalyticsEvent.Variations.editVariationAttributeOptionsDoneButtonTapped(productID: viewModel.variation.productID,
                                                                                                          variationID: viewModel.variation.productVariationID))
    }

    func presentAttributeOptions(for existingAttribute: ProductAttribute?) {
        guard let existingAttribute = existingAttribute else {
            return
        }

        let oldAttribute = viewModel.selectedOption(for: existingAttribute)

        let command = AttributeOptionListSelectorCommand(attribute: existingAttribute, selectedOption: oldAttribute)
        let attributeOptionListSelector = ListSelectorViewController(command: command) { [weak self] selected in
            self?.onAttributeOptionListSelectorCompletion(parentAttribute: existingAttribute, oldAttribute: oldAttribute, selectedRow: selected)
        }
        show(attributeOptionListSelector, sender: self)
    }

    func onAttributeOptionListSelectorCompletion(parentAttribute: ProductAttribute,
                                                 oldAttribute: ProductVariationAttribute?,
                                                 selectedRow: AttributeOptionListSelectorCommand.Row?) {
        let newAttribute: ProductVariationAttribute? = {
            switch selectedRow {
            case .option(let selectedOption):
                return ProductVariationAttribute(id: parentAttribute.attributeID, name: parentAttribute.name, option: selectedOption)
            default:
                return nil
            }
        }()

        viewModel.update(oldAttribute: oldAttribute, to: newAttribute)
        tableView.reloadData()
        updateDoneButton()
    }

    func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

private extension AttributePickerViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Attributes", comment: "Edit Product Attributes screen navigation title")
        static let headerAttributes = NSLocalizedString("Options", comment: "Header of attributes section in Edit Product Attributes screen")
        static let anyOption = NSLocalizedString("Any", comment: "Product variation attribute description where the attribute is set to any value.")
    }
}
