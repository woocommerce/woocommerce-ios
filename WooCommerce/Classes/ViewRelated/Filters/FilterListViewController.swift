import Combine
import SwiftUI
import UIKit
import Yosemite

enum FilterSource: String {
    case orders
    case products
    case booking
}

protocol HumanReadable {
    var readableString: String { get }
}

/// The view model protocol for filtering a list of models with generic filters.
///
protocol FilterListViewModel {
    /// The type of the final value returned to the caller of `FilterListViewController`.
    associatedtype Criteria: Equatable, HumanReadable

    // Filter Action UI configuration

    /// The title of the Filter CTA at the bottom.
    var filterActionTitle: String { get }

    // Data source

    /// A list of view models of any filter types that are displayed on the filter list selector.
    /// Tapping on each filter type row navigates to another list selector for the filter value.
    var filterTypeViewModels: [FilterTypeViewModel] { get }

    /// The final value returned to the caller of `FilterListViewController`.
    var criteria: Criteria { get }

    /// Whether to display the entry point to the filter history
    var shouldShowHistory: Bool { get }

    /// The entry point where the filter was opened
    var source: FilterSource { get }

    // Navigation & Actions

    /// Retrieves past filters
    func retrieveFilterHistory() async throws -> [Criteria]

    /// Applies a filter in the history
    func applyPastFilter(_ filter: Criteria)

    /// Saves a selected filter to the history
    func saveSelectedFilterToHistory(_ filter: Criteria)

    /// Removes a filter from the history
    func removeFilterFromHistory(_ filter: Criteria)

    /// Removes all saved filters from the history
    func clearAllFilterHistory()

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
    // Multi-select list selector with fixed options
    case multiSelectStaticOptions(options: [FilterType])
    // Filter list selector for categories linked to that site id, retrieved dynamically
    case productCategories(siteID: Int64)
    // Filter list selector for order statuses
    case ordersStatuses(allowedStatuses: [OrderStatus])
    // Filter list selector for date range
    case ordersDateRange
    // Filter list selector for products
    case products(siteID: Int64)
    // Filter list selector for customer
    case customer(siteID: Int64)
    // Filter list selector for booking team member
    case bookingResource(siteID: Int64)
    // Filter list selector for bookable product
    case bookableProduct(siteID: Int64)
    // Filter list selector for booking date time
    case bookingDateTime
    // Filter list selector for booking customers
    case bookingCustomers(siteID: Int64)
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
    private var historyBarButtonItem: UIBarButtonItem?

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
            if viewModel.filterTypeViewModels.numberOfActiveFilters > 0 {
                viewModel.saveSelectedFilterToHistory(criteria)
            }
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

    @objc private func showFilterHistory() {
        ServiceLocator.analytics.track(event: .FilterHistory.trackEntryPointTapped(from: viewModel.source))
        let controller = FilterHistoryViewHostingController(viewModel: viewModel, onSelection: { [weak self] selectedCriteria in
            guard let self else { return }
            viewModel.applyPastFilter(selectedCriteria)
            listSelectorCommand.data = viewModel.filterTypeViewModels
            updateUI(numberOfActiveFilters: viewModel.filterTypeViewModels.numberOfActiveFilters)
            listSelector.reloadData()
        })
        present(controller, animated: true)
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

        let clearAllButtonTitle = NSLocalizedString("Clear all", comment: "This is a button label that appears in the navigation bar of a filter screen, allowing users to clear all active filters that have been applied to a list.")
        clearAllBarButtonItem = UIBarButtonItem(title: clearAllButtonTitle, style: .plain, target: self, action: #selector(clearAllButtonTapped))

        if viewModel.shouldShowHistory {
            historyBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "clock"), style: .plain, target: self, action: #selector(showFilterHistory))
            historyBarButtonItem?.accessibilityHint = NSLocalizedString(
                "filterListViewController.historyBarButtonItem.accessibilityHint",
                value: "Filter history",
                comment: "Accessibility hint for the filter history button on the filter list screen"
            )
        }
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
                guard let self else { return }
                selected.selectedValue = selectedOption
                updateUI(numberOfActiveFilters: viewModel.filterTypeViewModels.numberOfActiveFilters)
                listSelector.reloadData()
            }

            switch selected.listSelectorConfig {
            case .staticOptions(let options):
                let command = StaticListSelectorCommand(navigationBarTitle: selected.title,
                                                        data: options,
                                                        selected: selected.selectedValue,
                                                        hostViewController: self)
                self.selectedFilterValueSubscription = command.onItemSelected.sink {
                    selectedValueAction($0)
                }
                let staticListSelector = ListSelectorViewController(command: command, tableViewStyle: .plain) { _ in }
                self.listSelector.navigationController?.pushViewController(staticListSelector, animated: true)
            case .multiSelectStaticOptions(let options):
                let selectedItems: [any FilterType] = {
                    if let wrapper = selected.selectedValue as? MultipleFilterSelection {
                        return wrapper.items
                    }
                    return []
                }()

                let multiSelectView = MultiSelectListView(
                    title: selected.title,
                    options: options,
                    initialSelection: selectedItems,
                    onSelection: { selectedOptions in
                        let filterType = MultipleFilterSelection(items: selectedOptions)
                        selectedValueAction(filterType)
                    }
                )
                let hostingController = UIHostingController(rootView: multiSelectView)
                self.listSelector.navigationController?.pushViewController(hostingController, animated: true)
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
            case .products(let siteID):
                let selectedProductID: [Int64] = {
                    guard let filter = selected.selectedValue as? FilterOrdersByProduct else {
                        return []
                    }
                    return [filter.id]
                }()

                let controller: WooNavigationController = {
                    let productSelectorViewModel = ProductSelectorViewModel(
                        siteID: siteID,
                        source: .orderFilter,
                        selectedItemIDs: selectedProductID,
                        onProductSelectionStateChanged: { [weak self] product, _ in
                            guard let self else { return }

                            let filterType = FilterOrdersByProduct(id: product.productID, name: product.name)
                            selectedValueAction(filterType)
                            self.listSelector.dismiss(animated: true)
                        },
                        onCloseButtonTapped: { [weak self] in
                            guard let self else { return }

                            self.listSelector.dismiss(animated: true)
                        }
                    )
                    return WooNavigationController(rootViewController: ProductSelectorViewController(configuration: .configurationForOrder,
                                                                                                     viewModel: productSelectorViewModel))
                }()
                self.listSelector.present(controller, animated: true)

            case .customer(let siteID):
                let selectedCustomerID = (selected.selectedValue as? CustomerFilter)?.id
                let controller: CustomerSelectorViewController = {
                    return CustomerSelectorViewController(
                        siteID: siteID,
                        configuration: .configurationForOrderFilter,
                        addressFormViewModel: nil,
                        selectedCustomerID: selectedCustomerID,
                        onCustomerSelected: { customer in
                            let filterType = CustomerFilter(customer: customer)
                            selectedValueAction(filterType)
                        }
                    )
                }()

                self.listSelector.navigationController?.pushViewController(controller, animated: true)
            case .bookingResource(let siteID):
                let selectedMembers: [BookingTeamMemberFilter] = {
                    if let wrapper = selected.selectedValue as? MultipleFilterSelection {
                        return wrapper.items.compactMap { $0 as? BookingTeamMemberFilter }
                    }
                    return []
                }()
                let syncable = TeamMemberListSyncable(siteID: siteID)
                let viewModel = SyncableListSelectorViewModel(syncable: syncable)
                let memberListSelectorView = SyncableListSelectorView(
                    viewModel: viewModel,
                    syncable: syncable,
                    initialSelections: selectedMembers,
                    onSelection: { resources in
                        let filterType = MultipleFilterSelection(items: resources)
                        selectedValueAction(filterType)
                    }
                )
                let hostingController = UIHostingController(rootView: memberListSelectorView)
                listSelector.navigationController?.pushViewController(hostingController, animated: true)

            case .bookableProduct(let siteID):
                let selectedProducts: [BookingProductFilter] = {
                    if let wrapper = selected.selectedValue as? MultipleFilterSelection {
                        return wrapper.items.compactMap { $0 as? BookingProductFilter }
                    }
                    return []
                }()
                let syncable = BookableProductListSyncable(siteID: siteID)
                let viewModel = SyncableListSelectorViewModel(syncable: syncable)
                let memberListSelectorView = SyncableListSelectorView(
                    viewModel: viewModel,
                    syncable: syncable,
                    initialSelections: selectedProducts,
                    onSelection: { filters in
                        let filterType = MultipleFilterSelection(items: filters)
                        selectedValueAction(filterType)
                    }
                )
                let hostingController = UIHostingController(rootView: memberListSelectorView)
                listSelector.navigationController?.pushViewController(hostingController, animated: true)
            case .bookingDateTime:
                let selectedDateRange = selected.selectedValue as? BookingDateRangeFilter
                let dateTimeFilterView = BookingDateTimeFilterView(
                    startDate: selectedDateRange?.startDate,
                    endDate: selectedDateRange?.endDate,
                    onSelection: { startDate, endDate in
                        let filterType = BookingDateRangeFilter(startDate: startDate, endDate: endDate)
                        selectedValueAction(filterType)
                    }
                )
                let hostingController = UIHostingController(rootView: dateTimeFilterView)
                listSelector.navigationController?.pushViewController(hostingController, animated: true)

            case .bookingCustomers(let siteID):
                let selectedCustomers: [BookingCustomerFilter] = {
                    if let wrapper = selected.selectedValue as? MultipleFilterSelection {
                        return wrapper.items.compactMap { $0 as? BookingCustomerFilter }
                    }
                    return []
                }()
                let syncable = CustomerListSyncable(siteID: siteID)
                let viewModel = SyncableListSelectorViewModel(syncable: syncable)
                let memberListSelectorView = SyncableListSelectorView(
                    viewModel: viewModel,
                    syncable: syncable,
                    initialSelections: selectedCustomers,
                    onSelection: { customers in
                        let filterType = MultipleFilterSelection(items: customers)
                        selectedValueAction(filterType)
                    }
                )
                let hostingController = UIHostingController(rootView: memberListSelectorView)
                listSelector.navigationController?.pushViewController(hostingController, animated: true)
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

        // Disables interactive dismiss action if there are changes so we can prompt the discard changes alert.
        isModalInPresentation = hasFilterChanges()
    }

    func updateListSelectorNavigationTitle(numberOfActiveFilters: Int) {
        listSelectorCommand.navigationBarTitle = numberOfActiveFilters > 0 ?
            String.localizedStringWithFormat(navigationBarTitleFormatWithActiveFilters, numberOfActiveFilters):
            navigationBarTitleWithoutActiveFilters
    }

    func updateClearAllActionVisibility(numberOfActiveFilters: Int) {
        let buttonItems: [UIBarButtonItem] = {
            var contents = [historyBarButtonItem].compactMap { $0 }
            if numberOfActiveFilters > 0, let clearAllBarButtonItem {
                contents.append(clearAllBarButtonItem)
            }
            return contents
        }()
        listSelector.navigationItem.rightBarButtonItems = buttonItems
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
            // Instead, just launch a webview to promote it.
            if let promotable = selected as? PromotableProductType, !promotable.isAvailable {
                return launchPromoteWebview(for: promotable)
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

            let action = UIAction { [weak self] action in
                self?.launchPromoteWebview(for: promotableType)
            }

            let button = UIButton(configuration: configuration, primaryAction: action)
            button.sizeToFit()

            return button
        }

        func launchPromoteWebview(for promotableType: PromotableProductType) {
            if let url = promotableType.promoteUrl, let viewController = hostViewController {
                WebviewHelper.launch(url, with: viewController)
                ServiceLocator.analytics.track(event: .ProductListFilter.productFilterListExploreButtonTapped(type: promotableType))
            }
        }
    }
}

/// Wrapper type for storing multiple filter selections
/// This allows arrays of FilterType items to be stored in FilterTypeViewModel.selectedValue
struct MultipleFilterSelection: FilterType {
    let items: [any FilterType]

    var isActive: Bool {
        return !items.isEmpty
    }

    var description: String {
        if items.isEmpty {
            return NSLocalizedString(
                "multipleFilterSelection.any",
                value: "Any",
                comment: "Display label for when no filter selected."
            )
        } else if items.count == 1 {
            return items.first?.description ?? ""
        } else {
            return "\(items.count)"
        }
    }

    init(items: [any FilterType]) {
        self.items = items
    }
}
