import UIKit
import Yosemite
import protocol WooFoundation.Analytics

/// EditAttributesViewController: Displays the list of attributes for a product.
///
final class EditAttributesViewController: UIViewController {

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!
    @IBOutlet private var tableView: UITableView!

    private let viewModel: EditAttributesViewModel

    private let noticePresenter: NoticePresenter
    private let analytics: Analytics

    /// Assign this closure to be notified after a variation is created.
    ///
    var onVariationCreation: ((Product) -> Void)?

    /// Assign this closure to be notified after an attribute  is created or updated.
    ///
    var onAttributesUpdate: ((Product) -> Void)?

    init(viewModel: EditAttributesViewModel,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         analytics: Analytics = ServiceLocator.analytics) {
        self.viewModel = viewModel
        self.noticePresenter = noticePresenter
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAddButton()
        configureAddButtonSeparator()
        registerTableViewCells()
        configureTableView()
        configureNavigationBar()
        handleSwipeBackGesture()
    }
}

// MARK: - View Configuration
private extension EditAttributesViewController {
    func registerTableViewCells() {
        tableView.registerNib(for: ImageAndTitleAndTextTableViewCell.self)
    }

    func configureAddButton() {
        addButton.setTitle(Localization.addNewAttribute, for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.applySecondaryButtonStyle()
    }

    func configureAddButtonSeparator() {
        addButtonSeparator.backgroundColor = .systemColor(.separator)
    }

    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.removeLastCellSeparator()
    }

    func configureNavigationBar() {
        configureTitle()
        configureRightButton()
    }

    func configureTitle() {
        title = Localization.title
    }

    func configureRightButton() {
        guard viewModel.showDoneButton else {
            return
        }
        let rightBarButton = UIBarButtonItem(title: Localization.next, style: .plain, target: self, action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }
}

// MARK: Button Actions & Navigation Handling
extension EditAttributesViewController {
    @objc private func doneButtonTapped() {
        navigateToCreateVariation()
    }

    @objc private func addButtonTapped() {
        navigateToAddAttributeViewController()
        analytics.track(event: .Variations.addAttributeButtonTapped(productID: viewModel.product.productID))
    }

    /// Navigates to an intermediate screen where we can generate our first variation.
    ///
    private func navigateToCreateVariation() {
        let createVariationViewController = EmptyStateViewController(
            style: .basic,
            configuration: .withButton(
                message: .init(string: Localization.attributesAddedTitle),
                image: .welcomeImage,
                details: Localization.attributesAddedInfo,
                buttonTitle: Localization.generateButtonTitle,
                onTap: { [weak self] _ in
                    self?.presentGenerateVariationOptions()
                }
            ))
        createVariationViewController.title = Localization.generateTitle
        show(createVariationViewController, sender: self)
    }

    /// Displays a bottom sheet allowing the merchant to choose whether to generate one variation or to generate all variations.
    ///
    private func presentGenerateVariationOptions() {
        let presenter = GenerateVariationsOptionsPresenter(baseViewController: self)
        presenter.presentGenerationOptions(sourceView: self.view) { [weak self] selectedOption in
            switch selectedOption {
            case .single:
                self?.createVariation()
            case .all:
                self?.generateAllVariations()
            }
        }
    }

    /// Creates a variation and presents a loading screen while it is created.
    ///
    private func createVariation() {
        let progressViewController = InProgressViewController(viewProperties: .init(title: Localization.generatingVariation,
                                                                                    message: Localization.waitInstructions))
        present(progressViewController, animated: true)
        viewModel.generateVariation { [onVariationCreation, noticePresenter] result in
            progressViewController.dismiss(animated: true)

            guard let (product, _) = try? result.get() else {
                noticePresenter.enqueue(notice: .init(title: Localization.generateVariationError, feedbackType: .error))
                return
            }

            onVariationCreation?(product)
        }
    }

    /// Navigates to `AddAttributeViewController` and upon completion, update the product and clean the navigation stack
    ///
    private func navigateToAddAttributeViewController() {
        let addAttributeVM = AddAttributeViewModel(product: viewModel.product)
        let addAttributeViewController = AddAttributeViewController(viewModel: addAttributeVM) { [weak self] updatedProduct in
            guard let self = self else { return }
            self.viewModel.updateProduct(updatedProduct)
            self.onAttributesUpdate?(updatedProduct)
            self.tableView.reloadData()
        }
        show(addAttributeViewController, sender: self)
    }

    /// Navigates to `AddAttributeOptionsViewController` to provide delete/rename/edit-options functionality.
    /// Upon completion, update the product and notify invoker
    ///
    private func navigateToEditAttribute(_ attribute: ProductAttribute) {
        let editViewModel = AddAttributeOptionsViewModel(product: viewModel.product, attribute: .existing(attribute: attribute), allowsEditing: true)
        let editViewController = AddAttributeOptionsViewController(viewModel: editViewModel) { [weak self] updatedProduct in
            guard let self = self else { return }
            self.viewModel.updateProduct(updatedProduct)
            self.onAttributesUpdate?(updatedProduct)
            self.tableView.reloadData()
        }
        show(editViewController, sender: true)
    }

    /// Generates all possible variations for the product attributes.
    ///
    private func generateAllVariations() {
        let presenter = GenerateAllVariationsPresenter(baseViewController: self)
        viewModel.generateAllVariations() { [weak self, presenter] currentState in
            // Perform Presentation Actions
            presenter.handleStateChanges(state: currentState)

            // Perform other side effects
            switch currentState {
            case .finished(let variationsCreated, let updatedProduct):
                if variationsCreated {
                    self?.onVariationCreation?(updatedProduct)
                }
            default: break
            }
        }
    }
}

// MARK: - UITableView conformance
//
extension EditAttributesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.attributes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ImageAndTitleAndTextTableViewCell.self, for: indexPath)
        let cellViewModel = viewModel.attributes[indexPath.row]
        cell.updateUI(viewModel: cellViewModel)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let attribute = viewModel.productAttributeAtIndex(indexPath.row)
        navigateToEditAttribute(attribute)
    }
}

// MARK: Constants
private extension EditAttributesViewController {
    enum Localization {
        static let addNewAttribute = NSLocalizedString("Add New Attribute", comment: "Action to add new attribute on the Product Attributes screen")
        static let title = NSLocalizedString("Edit Attributes", comment: "Navigation title for the Product Attributes screen")
        static let next = NSLocalizedString("Next", comment: "Action navigate to the variation creation screen")

        static let generateTitle = NSLocalizedString("Variations", comment: "Title for the generate first variation screen")
        static let attributesAddedTitle = NSLocalizedString("Attributes added!", comment: "Primary text for the generate first variation screen")
        static let attributesAddedInfo = NSLocalizedString("Now that you’ve added attributes, you can create your first variation!",
                                                           comment: "Info text for the generate first variation screen")
        static let generateButtonTitle = NSLocalizedString("Generate Variation", comment: "Title of the action to generate the first variation")

        static let generatingVariation = NSLocalizedString("Generating Variation", comment: "Title for the progress screen while generating a variation")
        static let waitInstructions = NSLocalizedString("Please wait while we create the new variation",
                                                        comment: "Instructions for the progress screen while generating a variation")
        static let generateVariationError = NSLocalizedString("The variation couldn't be generated.",
                                                              comment: "Error title when failing to generate a variation.")
    }
}
