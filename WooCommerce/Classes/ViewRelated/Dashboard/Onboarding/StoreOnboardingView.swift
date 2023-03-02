import SwiftUI
import struct Yosemite.Site

/// Hosting controller for `StoreOnboardingView`.
///
final class StoreOnboardingViewHostingController: UIHostingController<StoreOnboardingView> {
    private let viewModel: StoreOnboardingViewModel
    private let sourceNavigationController: UINavigationController
    private var coordinator: StoreOnboardingCoordinator?

    init(viewModel: StoreOnboardingViewModel,
         navigationController: UINavigationController,
         site: Site,
         viewAllTapped: (() -> Void)? = nil,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.sourceNavigationController = navigationController
        super.init(rootView: StoreOnboardingView(viewModel: viewModel,
                                                 viewAllTapped: viewAllTapped,
                                                 shareFeedbackAction: shareFeedbackAction))
        rootView.taskTapped = { [weak self] task in
            guard let self else { return }
            let coordinator = StoreOnboardingCoordinator(navigationController: self.sourceNavigationController, site: site)
            self.coordinator = coordinator
            coordinator.start(task: task)
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

    private let viewModel: StoreOnboardingViewModel
    private let viewAllTapped: (() -> Void)?
    private let shareFeedbackAction: (() -> Void)?

    init(viewModel: StoreOnboardingViewModel,
         viewAllTapped: (() -> Void)? = nil,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.viewAllTapped = viewAllTapped
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
                                       shareFeedbackAction: shareFeedbackAction)

                // Task list
                VStack(alignment: .leading, spacing: Layout.verticalSpacingBetweenTasks) {
                    ForEach(viewModel.tasksForDisplay) { taskViewModel in
                        let isLastTask = taskViewModel == viewModel.tasksForDisplay.last

                        StoreOnboardingTaskView(viewModel: taskViewModel,
                                                showDivider: !isLastTask) { task in
                            taskTapped(task)
                        }
                    }
                }

                // View all button
                viewAllButton(action: viewAllTapped, text: String(format: Localization.viewAll, viewModel.taskViewModels.count))
                    .renderedIf(!viewModel.isExpanded)

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
        StoreOnboardingView(viewModel: .init(isExpanded: false))

        StoreOnboardingView(viewModel: .init(isExpanded: true))
    }
}
