import SwiftUI
import struct Yosemite.StoreOnboardingTask

/// Hosting controller for `StoreOnboardingView`.
///
final class StoreOnboardingViewHostingController: UIHostingController<StoreOnboardingView> {
    private let viewModel: StoreOnboardingViewModel

    init(viewModel: StoreOnboardingViewModel,
         taskTapped: @escaping (StoreOnboardingTask) -> Void,
         viewAllTapped: (() -> Void)? = nil,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        super.init(rootView: StoreOnboardingView(viewModel: viewModel,
                                                 taskTapped: taskTapped,
                                                 viewAllTapped: viewAllTapped,
                                                 shareFeedbackAction: shareFeedbackAction))
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
    @ObservedObject private var viewModel: StoreOnboardingViewModel

    private let taskTapped: (StoreOnboardingTask) -> Void
    private let viewAllTapped: (() -> Void)?
    private let shareFeedbackAction: (() -> Void)?

    init(viewModel: StoreOnboardingViewModel,
         taskTapped: @escaping (StoreOnboardingTask) -> Void,
         viewAllTapped: (() -> Void)? = nil,
         shareFeedbackAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.taskTapped = taskTapped
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
        StoreOnboardingView(viewModel: .init(isExpanded: false, siteID: 0), taskTapped: { _ in })

        StoreOnboardingView(viewModel: .init(isExpanded: true, siteID: 0), taskTapped: { _ in })
    }
}
