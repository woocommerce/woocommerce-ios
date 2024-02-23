import Combine
import UIKit
import Yosemite

/// The view model protocol for filtering a list of models with generic filters.
///
protocol FilterListViewModel {
    /// The type of the final value returned to the caller of `FilterListViewController`.
    associatedtype Criteria: Equatable

    // Filter Action UI configuration

    /// The title of the Filter CTA at the bottom.
    var filterActionTitle: String { get }

    // Data source

    /// A list of view models of any filter types that are displayed on the filter list selector.
    /// Tapping on each filter type row navigates to another list selector for the filter value.
    var filterTypeViewModels: [FilterTypeViewModel] { get }

    /// The final value returned to the caller of `FilterListViewController`.
    var criteria: Criteria { get }

    // Navigation & Actions

    /// Resets the filter criteria.
    func clearAll()
}

/// Contains data for rendering the filter list selector and the list selector for the filter value.
final class FilterTypeViewModel {
    /// The selected filter value.
    var selectedValue: FilterType

    /// Used to display in each filter type row, and the navigation bar title of the filter value list selector.
    let title: String

    /// The configuration of the filter value list selector.
    let listSelectorConfig: FilterListValueSelectorConfig

    init(title: String,
         listSelectorConfig: FilterListValueSelectorConfig,
         selectedValue: FilterType) {
        self.title = title
        self.listSelectorConfig = listSelectorConfig
        self.selectedValue = selectedValue
    }
}

/// Describes the configuration of the filter value list selector.
enum FilterListValueSelectorConfig {
    // Standard list selector with fixed options
    case staticOptions(options: [FilterType])
    // Filter list selector for categories linked to that site id, retrieved dynamically
    case productCategories(siteID: Int64)
    // Filter list selector for order statuses
    case ordersStatuses(allowedStatuses: [OrderStatus])
    // Filter list selector for date range
    case ordersDateRange
    // Filter list selector for customer
    case customer
}

/// Contains data for rendering a filter type row.
struct FilterListCellViewModel: Equatable {
    /// The title of the filter type.
    let title: String

    /// The user-facing value of the filter type.
    let value: String
}

/// A type that can be used to filter a list of models.
protocol FilterType {
    /// The user-facing description of the filter value.
    var description: String { get }

    /// Whether the filter is set to a non-empty value.
    var isActive: Bool { get }
}

/// Allows the user to filter a list of models with generic filters.
/// The UI consists of a list of filters at the top and a Filter CTA at the bottom that is always visible to apply the filters.
/// Tapping on a filter in the list navigates to a list of options for the filter.
///
final class FilterListViewController<ViewModel: FilterListViewModel>: UIViewController {

    @IBOutlet private weak var navigationControllerContainerView: UIView!
    @IBOutlet private weak var filterActionContainerView: UIView!

    private let viewModel: ViewModel
    private let originalCriteria: ViewModel.Criteria
    private let listSelectorCommand: FilterListSelectorCommand

    private lazy var listSelector: ListSelectorViewController
        <FilterListSelectorCommand, FilterListSelectorCommand.Model, FilterListSelectorCommand.Cell> = {
            return ListSelectorViewController(command: listSelectorCommand, tableViewStyle: .plain) { [weak self] _ in }
    }()

    private var clearAllBarButtonItem: UIBarButtonItem?

    private var selectedFilterTypeSubscription: AnyCancellable?
    private var selectedFilterValueSubscription: AnyCancellable?

    private let onFilterAction: (ViewModel.Criteria) -> Void
    private let onClearAction: () -> Void
    private let onDismissAction: () -> Void

    // Strings.

    private let navigationBarTitleWithoutActiveFilters =
        NSLocalizedString("Filters", comment: "Navigation bar title format for filtering a list of products without filters applied.")
    private let navigationBarTitleFormatWithActiveFilters =
        NSLocalizedString("Filters (%ld)", comment: "Navigation bar title format for filtering a list of products with filters applied.")

    /// - Parameters:
    ///   - viewModel: Used to render the filter list selector and the selected filter value list selector.
    ///   - onFilterAction: Called when the user taps on the Filter CTA.
    ///   - onClearAction: Called when the user taps on the Clear CTA.
    ///   - onDismissAction: Called when the user taps on the Dismiss CTA.
    init(viewModel: ViewModel,
         onFilterAction: @escaping (ViewModel.Criteria) -> Void,
         onClearAction: @escaping () -> Void,
         onDismissAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.originalCriteria = viewModel.criteria
        self.onFilterAction = onFilterAction
        self.onClearAction = onClearAction
        self.onDismissAction = onDismissAction
        self.listSelectorCommand = FilterListSelectorCommand(data: viewModel.filterTypeViewModels)
        super.init(nibName: "FilterListViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureChildNavigationController()
        configureBottomFilterButtonContainerView()
        observeListSelectorCommandItemSelection()
        updateUI(numberOfActiveFilters: viewModel.filterTypeViewModels.numberOfActiveFilters)
    }

    // MARK: - Navigation
    //
    @objc private func filterActionButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            let criteria = self.viewModel.criteria
            self.onFilterAction(criteria)
        }
    }

    @objc private func dismissButtonTapped() {
        if hasFilterChanges() {
            UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
                self?.dismiss(animated: true) {}
            })
            return
        }

        dismiss(animated: true) { [weak self] in
            self?.onDismissAction()
        }
    }

    @objc private func clearAllButtonTapped() {
        viewModel.clearAll()
        listSelectorCommand.data = viewModel.filterTypeViewModels
        updateUI(numberOfActiveFilters: viewModel.filterTypeViewModels.numberOfActiveFilters)
        listSelector.reloadData()
        onClearAction()
    }
}

// MARK: - View Configuration
//
private extension FilterListViewController {
    func configureNavigation() {
        let dismissButtonTitle = NSLocalizedString("Dismiss", comment: "Button title for dismissing filtering a list.")
        listSelector.navigationItem.leftBarButtonItem = UIBarButtonItem(title: dismissButtonTitle,
                                                                        style: .plain,
                                                                        target: self,
                                                                        action: #selector(dismissButtonTapped))

        let clearAllButtonTitle = NSLocalizedString("Clear all", comment: "Button title for clearing all filters for the list.")
        clearAllBarButtonItem = UIBarButtonItem(title: clearAllButtonTitle, style: .plain, target: self, action: #selector(clearAllButtonTapped))

        // Disables interactive dismiss action so that we can prompt the discard changes alert.
        isModalInPresentation = true
    }

    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func observeListSelectorCommandItemSelection() {
        selectedFilterTypeSubscription = listSelectorCommand.onItemSelected.sink { [weak self] selected in
            guard let self = self else {
                return
            }

            let selectedValueAction: (FilterType) -> Void = { [weak self] selectedOption in
                guard let self = self else {
                    return
                }
                if selectedOption.description != selected.selectedValue.description {
                    selected.selectedValue = selectedOption
                    self.updateUI(numberOfActiveFilters: self.viewModel.filterTypeViewModels.numberOfActiveFilters)
                    self.listSelector.reloadData()
                }
            }

            switch selected.listSelectorConfig {
            case .staticOptions(let options):
                let command = StaticListSelectorCommand(navigationBarTitle: selected.title,
                                                        data: options,
                                                        selected: selected.selectedValue,
                                                        hostViewController: self)
                self.selectedFilterValueSubscription = command.onItemSelected.sink { selectedValueAction($0) }
                let staticListSelector = ListSelectorViewController(command: command, tableViewStyle: .plain) { _ in }
                self.listSelector.navigationController?.pushViewController(staticListSelector, animated: true)
            case let .productCategories(siteID):
                let selectedProductCategory = selected.selectedValue as? ProductCategory
                let filterProductCategoryListViewController = FilterProductCategoryListViewController(siteID: siteID,
                                                                                                      selectedCategory: selectedProductCategory,
                                                                                                      onProductCategorySelection: selectedValueAction)
                self.listSelector.navigationController?.pushViewController(filterProductCategoryListViewController, animated: true)
            case .ordersStatuses(let allowedStatuses):
                let selectedOrderFilters = selected.selectedValue as? Array<OrderStatusEnum> ?? []
                let statusesFilterVC = OrderStatusFilterViewController(selected: selectedOrderFilters, allowedStatuses: allowedStatuses) { statuses in
                    selected.selectedValue = statuses.isEmpty ? nil : statuses
                    self.updateUI(numberOfActiveFilters: self.viewModel.filterTypeViewModels.numberOfActiveFilters)
                    self.listSelector.reloadData()
                }
                self.listSelector.navigationController?.pushViewController(statusesFilterVC, animated: true)
            case .ordersDateRange:
                let selectedOrderFilter = selected.selectedValue as? OrderDateRangeFilter
                let datesFilterVC = OrderDatesFilterViewController(selected: selectedOrderFilter) { dateRangeFilter in
                    selected.selectedValue = dateRangeFilter
                    self.updateUI(numberOfActiveFilters: self.viewModel.filterTypeViewModels.numberOfActiveFilters)
                    self.listSelector.reloadData()
                }
                self.listSelector.navigationController?.pushViewController(datesFilterVC, animated: true)

            case .customer:
                let selectedOrderFilter = selected.selectedValue as? CustomerFilter
                print("Customer filter not implemented")
            }
        }
    }

    func configureChildNavigationController() {
        let navigationController = WooNavigationController(rootViewController: listSelector)
        addChild(navigationController)
        navigationControllerContainerView.addSubview(navigationController.view)
        navigationController.didMove(toParent: self)

        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationControllerContainerView.pinSubviewToAllEdges(navigationController.view)
    }

    func configureBottomFilterButtonContainerView() {
        let buttonContainerViewModel = BottomButtonContainerView.ViewModel(style: .primary,
                                                                           title: viewModel.filterActionTitle) { [weak self] _ in
                                                                            self?.filterActionButtonTapped()
        }
        let buttonContainerView = BottomButtonContainerView(viewModel: buttonContainerViewModel)
        filterActionContainerView.addSubview(buttonContainerView)
        filterActionContainerView.pinSubviewToAllEdges(buttonContainerView)
        filterActionContainerView.setContentCompressionResistancePriority(.required, for: .vertical)
        filterActionContainerView.setContentHuggingPriority(.required, for: .vertical)
    }
}

// MARK: - Updates from data changes
//
private extension FilterListViewController {
    func updateUI(numberOfActiveFilters: Int) {
        updateListSelectorNavigationTitle(numberOfActiveFilters: numberOfActiveFilters)
        updateClearAllActionVisibility(numberOfActiveFilters: numberOfActiveFilters)
    }

    func updateListSelectorNavigationTitle(numberOfActiveFilters: Int) {
        listSelectorCommand.navigationBarTitle = numberOfActiveFilters > 0 ?
            String.localizedStringWithFormat(navigationBarTitleFormatWithActiveFilters, numberOfActiveFilters):
            navigationBarTitleWithoutActiveFilters
    }

    func updateClearAllActionVisibility(numberOfActiveFilters: Int) {
        listSelector.navigationItem.rightBarButtonItem = numberOfActiveFilters > 0 ? clearAllBarButtonItem: nil
    }
}

// MARK: Private helpers
//
private extension FilterListViewController {
    func hasFilterChanges() -> Bool {
        return viewModel.criteria != originalCriteria
    }
}

private extension FilterListViewController {
    final class FilterListSelectorCommand: ListSelectorCommand {
        typealias Cell = TitleAndValueTableViewCell
        typealias Model = FilterTypeViewModel

        var navigationBarTitle: String?

        let selected: FilterTypeViewModel? = nil

        fileprivate(set) var data: [FilterTypeViewModel]

        private let onItemSelectedSubject = PassthroughSubject<FilterTypeViewModel, Never>()
        var onItemSelected: AnyPublisher<FilterTypeViewModel, Never> {
            onItemSelectedSubject.eraseToAnyPublisher()
        }

        init(data: [FilterTypeViewModel]) {
            self.data = data
        }

        func isSelected(model: FilterTypeViewModel) -> Bool {
            selected?.cellViewModel == model.cellViewModel
        }

        func handleSelectedChange(selected: FilterTypeViewModel, viewController: ViewController) {
            onItemSelectedSubject.send(selected)
        }

        func configureCell(cell: TitleAndValueTableViewCell, model: FilterTypeViewModel) {
            cell.selectionStyle = .default
            cell.updateUI(title: model.cellViewModel.title, value: model.cellViewModel.value)
            cell.accessoryType = .disclosureIndicator
        }
    }
}

private extension FilterListViewController {
    final class StaticListSelectorCommand: ListSelectorCommand {
        typealias Cell = BasicTableViewCell
        typealias Model = FilterType

        let navigationBarTitle: String?

        var selected: FilterType? = nil

        let data: [FilterType]

        /// Parent view controller. Used to launch the promoted url web view.
        ///
        private weak var hostViewController: UIViewController?

        private let onItemSelectedSubject = PassthroughSubject<FilterType, Never>()
        var onItemSelected: AnyPublisher<FilterType, Never> {
            onItemSelectedSubject.eraseToAnyPublisher()
        }

        init(navigationBarTitle: String, data: [FilterType], selected: FilterType, hostViewController: UIViewController? = nil) {
            self.navigationBarTitle = navigationBarTitle
            self.data = data
            self.selected = selected
            self.hostViewController = hostViewController
        }

        func isSelected(model: FilterType) -> Bool {
            selected?.description == model.description
        }

        func handleSelectedChange(selected: FilterType, viewController: ViewController) {
            // Do not allow selection for an unavailable promotable type.
            if let promotable = selected as? PromotableProductType, !promotable.isAvailable {
                return
            }

            onItemSelectedSubject.send(selected)
            self.selected = selected
        }

        func configureCell(cell: BasicTableViewCell, model: FilterType) {
            cell.textLabel?.text = model.description
            cell.accessibilityIdentifier = model.description
            cell.accessoryView = nil

            if let promotable = model as? PromotableProductType, !promotable.isAvailable {
                cell.accessoryView = createPromoteButton(promotableType: promotable)
            }
        }

        func createPromoteButton(promotableType: PromotableProductType) -> UIButton {
            var configuration = UIButton.Configuration.tinted()
            configuration.cornerStyle = .small
            configuration.baseForegroundColor = .primary
            configuration.baseBackgroundColor = .primary
            configuration.buttonSize = .mini
            configuration.title = NSLocalizedString("Explore", comment: "Button title to explore an extension that isn't installed")

            let action = UIAction { action in
                if let url = promotableType.promoteUrl, let viewController = self.hostViewController {
                    WebviewHelper.launch(url, with: viewController)
                    ServiceLocator.analytics.track(event: .ProductListFilter.productFilterListExploreButtonTapped(type: promotableType))
                }
            }

            let button = UIButton(configuration: configuration, primaryAction: action)
            button.sizeToFit()

            return button
        }
    }
}
