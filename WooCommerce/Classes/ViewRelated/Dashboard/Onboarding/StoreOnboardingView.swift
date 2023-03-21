import SwiftUI
import struct Yosemite.Site
import struct Yosemite.StoreOnboardingTask

/// Hosting controller for `StoreOnboardingView`.
///
final class StoreOnboardingViewHostingController: SelfSizingHostingController<StoreOnboardingView>, UIAdaptivePresentationControllerDelegate {
    private let viewModel: StoreOnboardingViewModel
    private let sourceNavigationController: UINavigationController
    private let site: Site
    private weak var collapsedModePresentationControllerDelegate: UIAdaptivePresentationControllerDelegate?

    init(viewModel: StoreOnboardingViewModel,
         navigationController: UINavigationController,
         site: Site,
         collapsedModePresentationControllerDelegate: UIAdaptivePresentationControllerDelegate? = nil,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.sourceNavigationController = navigationController
        self.site = site
        self.collapsedModePresentationControllerDelegate = collapsedModePresentationControllerDelegate
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

            let delegate = viewModel.isExpanded ? self : self.collapsedModePresentationControllerDelegate
            let coordinator = StoreOnboardingCoordinator(navigationController: self.sourceNavigationController,
                                                         site: site,
                                                         presentationControllerDelegate: delegate)
            coordinator.start(task: task)
        }

        if !viewModel.isExpanded {
            rootView.viewAllTapped = { [weak self] in
                guard let self else { return }
                let coordinator = StoreOnboardingCoordinator(navigationController: self.sourceNavigationController,
                                                             site: site,
                                                             presentationControllerDelegate: self.collapsedModePresentationControllerDelegate)
                coordinator.start()
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

        Task {
            await reloadTasks()
        }
    }

    @MainActor
    private func reloadTasks() async {
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

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if let onboardingNavigationController = presentationController.presentedViewController as? UINavigationController,
           let vc = onboardingNavigationController.viewControllers.first,
           StoreOnboardingCoordinator.isRelatedToOnboardingTask(vc) {
            Task { @MainActor in
                await reloadTasks()
            }
        }
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
                    .renderedIf(viewModel.shouldShowViewAllButton)

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
        StoreOnboardingView(viewModel: .init(siteID: 0, isExpanded: false))

        StoreOnboardingView(viewModel: .init(siteID: 0, isExpanded: true))
    }
}
