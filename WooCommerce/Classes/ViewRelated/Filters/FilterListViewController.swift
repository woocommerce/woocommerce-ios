import UIKit

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
    // Example: Categories
    case custom
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

    private var cancellableSelectedFilterType: ObservationToken?
    private var cancellableSelectedFilterValue: ObservationToken?

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

    deinit {
        cancellableSelectedFilterType?.cancel()
        cancellableSelectedFilterValue?.cancel()
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
    @objc func filterActionButtonTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            let criteria = self.viewModel.criteria
            self.onFilterAction(criteria)
        }
    }

    @objc func dismissButtonTapped() {
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

    @objc func clearAllButtonTapped() {
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
        if #available(iOS 13.0, *) {
            isModalInPresentation = true
        }

        listSelector.removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func observeListSelectorCommandItemSelection() {
        cancellableSelectedFilterType?.cancel()
        cancellableSelectedFilterType = listSelectorCommand.onItemSelected.subscribe { [weak self] selected in
            guard let self = self else {
                return
            }

            switch selected.listSelectorConfig {
            case .staticOptions(let options):
                self.cancellableSelectedFilterValue?.cancel()
                let command = StaticListSelectorCommand(navigationBarTitle: selected.title,
                                                        data: options,
                                                        selected: selected.selectedValue)
                self.cancellableSelectedFilterValue = command.onItemSelected.subscribe { [weak self] selectedOption in
                    guard let self = self else {
                        return
                    }
                    if selectedOption.description != selected.selectedValue.description {
                        selected.selectedValue = selectedOption
                        self.updateUI(numberOfActiveFilters: self.viewModel.filterTypeViewModels.numberOfActiveFilters)
                        self.listSelector.reloadData()
                    }
                }
                let staticListSelector = ListSelectorViewController(command: command, tableViewStyle: .plain) { _ in }
                self.listSelector.navigationController?.pushViewController(staticListSelector, animated: true)
            case .custom:
                break
            }
        }
    }

    func configureChildNavigationController() {
        let navigationController = UINavigationController(rootViewController: listSelector)
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
        typealias Cell = SettingTitleAndValueTableViewCell
        typealias Model = FilterTypeViewModel

        var navigationBarTitle: String?

        let selected: FilterTypeViewModel? = nil

        fileprivate(set) var data: [FilterTypeViewModel]

        private let onItemSelectedSubject = PublishSubject<FilterTypeViewModel>()
        var onItemSelected: Observable<FilterTypeViewModel> {
            onItemSelectedSubject
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

        func configureCell(cell: SettingTitleAndValueTableViewCell, model: FilterTypeViewModel) {
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

        private let onItemSelectedSubject = PublishSubject<FilterType>()
        var onItemSelected: Observable<FilterType> {
            onItemSelectedSubject
        }

        init(navigationBarTitle: String, data: [FilterType], selected: FilterType) {
            self.navigationBarTitle = navigationBarTitle
            self.data = data
            self.selected = selected
        }

        func isSelected(model: FilterType) -> Bool {
            selected?.description == model.description
        }

        func handleSelectedChange(selected: FilterType, viewController: ViewController) {
            onItemSelectedSubject.send(selected)
            self.selected = selected
        }

        func configureCell(cell: BasicTableViewCell, model: FilterType) {
            cell.textLabel?.text = model.description
        }
    }
}
