import SwiftUI
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// Hosting controller for `StoreOnboardingView`.
///
final class StoreOnboardingViewHostingController: SelfSizingHostingController<StoreOnboardingView> {
    private let viewModel: StoreOnboardingViewModel
    private let sourceNavigationController: UINavigationController
    private let site: Site

    private lazy var coordinator = StoreOnboardingCoordinator(navigationController: sourceNavigationController,
                                                              site: site,
                                                              onTaskCompleted: { [weak self] task in
        guard let self else { return }
        self.reloadTasks()
        ServiceLocator.analytics.track(event: .StoreOnboarding.storeOnboardingTaskCompleted(task: task))
    }, reloadTasks: { [weak self] in
        self?.reloadTasks()
    })

    init(viewModel: StoreOnboardingViewModel,
         navigationController: UINavigationController,
         site: Site,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.sourceNavigationController = navigationController
        self.site = site
        super.init(rootView: StoreOnboardingView(viewModel: viewModel,
                                                 shareFeedbackAction: shareFeedbackAction))
        if #unavailable(iOS 16.0) {
            viewModel.onStateChange = { [weak self] in
                self?.view.invalidateIntrinsicContentSize()
            }
        }

        rootView.taskTapped = { [weak self] task in
            guard let self,
                  !task.isComplete else {
                return
            }
            ServiceLocator.analytics.track(event: .StoreOnboarding.storeOnboardingTaskTapped(task: task.type))
            self.coordinator.start(task: task)
        }

        if !viewModel.isExpanded {
            rootView.viewAllTapped = { [weak self] in
                guard let self else { return }
                self.coordinator.start()
            }
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBarAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadTasks()
    }

    private func reloadTasks() {
        Task { @MainActor in
            await viewModel.reloadTasks()
        }
    }

    /// Shows a transparent navigation bar without a bottom border.
    private func configureNavigationBarAppearance() {
        guard viewModel.isExpanded else {
            return
        }

        configureTransparentNavigationBar()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: .closeButton, style: .plain, target: self, action: #selector(dismissView))
    }

    @objc
    private func dismissView() {
        dismiss(animated: true)
    }
}

/// Shows a list of onboarding tasks for store setup with completion state.
struct StoreOnboardingView: View {
    /// Set externally in the hosting controller.
    var taskTapped: ((StoreOnboardingTask) -> Void)?
    /// Set externally in the hosting controller.
    var viewAllTapped: (() -> Void)?

    @ObservedObject private var viewModel: StoreOnboardingViewModel

    private let shareFeedbackAction: (() -> Void)?

    init(viewModel: StoreOnboardingViewModel,
         onTaskTapped: ((StoreOnboardingTask) -> Void)? = nil,
         onViewAllTapped: (() -> Void)? = nil,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.taskTapped = onTaskTapped
        self.viewAllTapped = onViewAllTapped
        self.shareFeedbackAction = shareFeedbackAction
    }

    var body: some View {
        if viewModel.isExpanded {
            ScrollView {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 0) {

            let verticalSpacing = viewModel.isExpanded ? Layout.VerticalSpacing.expandedMode : Layout.VerticalSpacing.collapsedMode
            VStack(alignment: viewModel.isExpanded ? .center : .leading, spacing: verticalSpacing) {
                // Progress view
                StoreSetupProgressView(isExpanded: viewModel.isExpanded,
                                       totalNumberOfTasks: viewModel.taskViewModels.count,
                                       numberOfTasksCompleted: viewModel.numberOfTasksCompleted,
                                       shareFeedbackAction: shareFeedbackAction,
                                       hideTaskListAction: viewModel.hideTaskList,
                                       isRedacted: viewModel.isRedacted,
                                       failedToLoadTasks: viewModel.failedToLoadTasks)
                .padding(.horizontal, Layout.padding)

                /// We want to show the dashboard card error view only on the dashboard screen.
                if viewModel.failedToLoadTasks && !viewModel.isExpanded {
                    DashboardCardErrorView(onRetry: {
                        ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .onboarding))
                        Task {
                            await viewModel.reloadTasks()
                        }
                    })
                    .padding(.horizontal, Layout.padding)
                } else {
                    // Task list
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.tasksForDisplay) { taskViewModel in
                            let isLastTask = taskViewModel == viewModel.tasksForDisplay.last

                            StoreOnboardingTaskView(viewModel: taskViewModel,
                                                    showDivider: !isLastTask,
                                                    isRedacted: viewModel.isRedacted) { task in
                                taskTapped?(task)
                            }
                                                    .shimmering(active: viewModel.isRedacted)
                        }
                    }
                    .padding(.horizontal, Layout.padding)

                    Divider()
                        .renderedIf(viewModel.shouldShowViewAllButton)
                        .padding(.leading, Layout.padding)

                    // View all button
                    viewAllButton(action: viewAllTapped, text: String(format: Localization.viewAll, viewModel.taskViewModels.count))
                        .renderedIf(viewModel.shouldShowViewAllButton)
                        .padding(.horizontal, Layout.padding)
                }

                Spacer()
                    .renderedIf(viewModel.isExpanded)
            }
            .padding(.top, Layout.padding)
            .padding(.bottom, viewModel.shouldShowViewAllButton ?
                                 Layout.padding: Layout.bottomPaddingWithoutViewAllButton)

            .if(!viewModel.isExpanded) { view in
                view.background(Color(uiColor: .listForeground(modal: false)))
                    .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
                    .padding(.horizontal, Layout.padding)
            }
        }
    }
}

// MARK: Helper methods
//
private extension StoreOnboardingView {
    @ViewBuilder
    func viewAllButton(action: (() -> Void)?, text: String) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(text)
                    .foregroundStyle(Color.accentColor)
                    .bodyStyle()
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
    }
}

private extension StoreOnboardingView {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let bottomPaddingWithoutViewAllButton: CGFloat = 1
        enum VerticalSpacing {
            static let collapsedMode: CGFloat = 16
            static let expandedMode: CGFloat = 40
        }
    }

    enum Localization {
        static let viewAll = NSLocalizedString(
            "storeOnboardingCardView.viewAll",
            value: "View all %1$d tasks",
            comment: "Button when tapped will show a screen with all the store setup tasks." +
            "%1$d represents the total number of tasks."
        )
    }
}

struct StoreOnboardingCardView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingView(viewModel: .init(siteID: 0, isExpanded: false))

        StoreOnboardingView(viewModel: .init(siteID: 0, isExpanded: true))
    }
}
