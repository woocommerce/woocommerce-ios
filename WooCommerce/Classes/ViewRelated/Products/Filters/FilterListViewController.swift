import UIKit

/// The command protocol for filtering a list of models with generic filters.
///
protocol FilterListCommand {
    associatedtype ListSelectorUICommand: ListSelectorCommand

    // Filter Action UI configuration

    /// The title of the Filter CTA at the bottom.
    var filterActionTitle: String { get }

    // List selector UI configuration

    /// The command for the list of filters above the Filter CTA.
    var filterListSelectorCommand: ListSelectorUICommand { get }

    // Clear all CTA visibility

    /// Whether the Clear All CTA is visible.
    var isClearAllActionVisible: Bool { get }

    /// Called when we should reload UI when one of the following changes:
    /// - Clear All CTA visibility
    /// - Filter list selector (`filterListSelectorCommand`) data
    var shouldReloadUIObservable: Observable<Void> { get }

    // Navigation & Actions

    /// Called when the user taps on the CTA to filter the list with the latest filters.
    func onFilterActionTapped()

    /// Called when the user dismisses the filter list screen.
    func onDismissActionTapped()

    /// Called when the user taps on the CTA to clear all filters.
    func onClearAllActionTapped()
}

/// Allows the user to filter a list of models with generic filters.
/// The UI consists of a list of filters at the top and a Filter CTA at the bottom that is always visible to apply the filters.
/// Tapping on a filter in the list navigates to a list of options for the filter.
///
final class FilterListViewController<Command: FilterListCommand>: UIViewController {

    @IBOutlet private weak var navigationControllerContainerView: UIView!
    @IBOutlet private weak var filterActionContainerView: UIView!

    private var command: Command
    private let rowType = SettingTitleAndValueTableViewCell.self

    private lazy var listSelector: ListSelectorViewController
        <Command.ListSelectorUICommand, Command.ListSelectorUICommand.Model, Command.ListSelectorUICommand.Cell> = {
            return ListSelectorViewController(command: command.filterListSelectorCommand) { [weak self] _ in
                self?.command.onDismissActionTapped()
            }
    }()

    private var clearAllBarButtonItem: UIBarButtonItem?

    private var observationToken: ObservationToken?

    init(command: Command) {
        self.command = command
        super.init(nibName: "FilterListViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        observationToken?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureClearAllActionVisibility()
        configureChildNavigationController()
        configureFilterActionContainerView()
        observeShouldReloadUI()
    }

    // MARK: - Navigation
    //
    @objc func filterActionButtonTapped() {
        command.onFilterActionTapped()
    }

    @objc func dismissButtonTapped() {
        command.onDismissActionTapped()
    }

    @objc func clearAllButtonTapped() {
        command.onClearAllActionTapped()
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
        view.backgroundColor = .listBackground
    }

    func configureClearAllActionVisibility() {
        // Until we have a `PassthroughSubject`/`BehaviorSubject`, we have to initialize the Clear All CTA visibility manually.
        listSelector.navigationItem.rightBarButtonItem = command.isClearAllActionVisible ? clearAllBarButtonItem: nil
    }

    func configureChildNavigationController() {
        let navigationController = UINavigationController(rootViewController: listSelector)
        addChild(navigationController)
        navigationControllerContainerView.addSubview(navigationController.view)
        navigationController.didMove(toParent: self)

        navigationController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationControllerContainerView.pinSubviewToAllEdges(navigationController.view)
    }

    func configureFilterActionContainerView() {
        let viewModel = BottomButtonContainerView.ViewModel(buttonTitle: command.filterActionTitle) { [weak self] in
            self?.filterActionButtonTapped()
        }
        let buttonContainerView = BottomButtonContainerView(viewModel: viewModel)
        filterActionContainerView.addSubview(buttonContainerView)
        filterActionContainerView.pinSubviewToAllEdges(buttonContainerView)
        filterActionContainerView.setContentCompressionResistancePriority(.required, for: .vertical)
        filterActionContainerView.setContentHuggingPriority(.required, for: .vertical)
    }

    func observeShouldReloadUI() {
        observationToken = command.shouldReloadUIObservable.subscribe { [weak self] in
            self?.listSelector.navigationItem.rightBarButtonItem = self?.command.isClearAllActionVisible == true ? self?.clearAllBarButtonItem: nil
            self?.listSelector.reloadData()
        }
    }
}
