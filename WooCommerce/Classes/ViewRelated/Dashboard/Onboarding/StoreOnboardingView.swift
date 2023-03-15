import SwiftUI
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// Hosting controller for `StoreOnboardingView`.
///
final class StoreOnboardingViewHostingController: SelfSizingHostingController<StoreOnboardingView> {
    private let viewModel: StoreOnboardingViewModel
    private let sourceNavigationController: UINavigationController
    private let site: Site
    private lazy var coordinator: StoreOnboardingCoordinator = .init(navigationController: sourceNavigationController,
                                                                     site: site)

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
            guard let self else { return }
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
        Task {
            await reloadTasks()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            await reloadTasks()
        }
    }

    @MainActor
    func reloadTasks() async {
        await viewModel.reloadTasks()
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
    var taskTapped: (StoreOnboardingTask) -> Void = { _ in }
    /// Set externally in the hosting controller.
    var viewAllTapped: (() -> Void)?

    @ObservedObject private var viewModel: StoreOnboardingViewModel

    private let shareFeedbackAction: (() -> Void)?

    init(viewModel: StoreOnboardingViewModel,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
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
        VStack {
            Color(uiColor: .listBackground)
                .frame(height: Layout.VerticalSpacing.collapsedMode)
                .renderedIf(!viewModel.isExpanded)

            let verticalSpacing = viewModel.isExpanded ? Layout.VerticalSpacing.expandedMode : Layout.VerticalSpacing.collapsedMode
            VStack(alignment: viewModel.isExpanded ? .center : .leading, spacing: verticalSpacing) {
                // Progress view
                StoreSetupProgressView(isExpanded: viewModel.isExpanded,
                                       totalNumberOfTasks: viewModel.taskViewModels.count,
                                       numberOfTasksCompleted: viewModel.numberOfTasksCompleted,
                                       shareFeedbackAction: shareFeedbackAction,
                                       isRedacted: viewModel.isRedacted)

                // Task list
                VStack(alignment: .leading, spacing: Layout.verticalSpacingBetweenTasks) {
                    ForEach(viewModel.tasksForDisplay) { taskViewModel in
                        let isLastTask = taskViewModel == viewModel.tasksForDisplay.last

                        StoreOnboardingTaskView(viewModel: taskViewModel,
                                                showDivider: !isLastTask,
                                                isRedacted: viewModel.isRedacted) { task in
                            taskTapped(task)
                        }
                                                .shimmering(active: viewModel.isRedacted)
                    }
                }

                // View all button
                viewAllButton(action: viewAllTapped, text: String(format: Localization.viewAll, viewModel.taskViewModels.count))
                    .renderedIf(!viewModel.isExpanded && !viewModel.isRedacted && viewModel.taskViewModels.count > 2)

                Spacer()
                    .renderedIf(viewModel.isExpanded)
            }
            .padding(insets: Layout.insets)
            .if(!viewModel.isExpanded) { $0.background(Color(uiColor: .listForeground(modal: false))) }

            Color(uiColor: .listBackground)
                .frame(height: Layout.VerticalSpacing.collapsedMode)
                .renderedIf(!viewModel.isExpanded)
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
            Text(text)
                .fontWeight(.semibold)
                .foregroundColor(.init(uiColor: .accent))
                .subheadlineStyle()
        }
    }
}

private extension StoreOnboardingView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        enum VerticalSpacing {
            static let collapsedMode: CGFloat = 16
            static let expandedMode: CGFloat = 40
        }
        static let verticalSpacingBetweenTasks: CGFloat = 4
    }

    enum Localization {
        static let viewAll = NSLocalizedString(
            "View all (%1$d)",
            comment: "Button when tapped will show a screen with all the store setup tasks." +
            "%1$d represents the total number of tasks."
        )
    }
}

struct StoreOnboardingCardView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingView(viewModel: .init(isExpanded: false, siteID: 0))

        StoreOnboardingView(viewModel: .init(isExpanded: true, siteID: 0))
    }
}
