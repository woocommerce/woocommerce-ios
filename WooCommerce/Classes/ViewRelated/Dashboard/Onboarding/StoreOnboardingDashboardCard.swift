import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.StoreOnboardingTask

/// Design-system presentation of Store Setup for the dashboard.
/// The expanded task list continues to use `StoreOnboardingView`.
struct StoreOnboardingDashboardCard: View {
    @ObservedObject private var viewModel: StoreOnboardingViewModel

    private let onTaskTapped: (StoreOnboardingTask) -> Void
    private let onViewAllTapped: ([StoreOnboardingTaskViewModel]) -> Void

    init(viewModel: StoreOnboardingViewModel,
         onTaskTapped: @escaping (StoreOnboardingTask) -> Void,
         onViewAllTapped: @escaping ([StoreOnboardingTaskViewModel]) -> Void) {
        self.viewModel = viewModel
        self.onTaskTapped = onTaskTapped
        self.onViewAllTapped = onViewAllTapped
    }

    var body: some View {
        StoreDashboardCardSurface {
            StoreDashboardCardHeader(DashboardCard.CardType.onboarding.name,
                                     showsError: viewModel.failedToLoadTasks,
                                     textStyle: .titleMedium.emphasized,
                                     topPadding: StorePadding.p5,
                                     bottomPadding: StorePadding.p3) {
                StoreDashboardCardOverflowMenu {
                    Button(Localization.hide, action: viewModel.hideTaskList)
                }
            }

            if viewModel.failedToLoadTasks {
                StoreDashboardCardErrorView(retry: reloadTasks)
            } else {
                StoreOnboardingDashboardProgress(
                    completedTasks: viewModel.numberOfTasksCompleted,
                    totalTasks: viewModel.taskViewModels.count,
                    isRedacted: viewModel.isRedacted
                )

                VStack(spacing: StoreSpacing.s0) {
                    ForEach(viewModel.tasksForDisplay) { task in
                        StoreOnboardingDashboardTaskRow(
                            viewModel: task,
                            isRedacted: viewModel.isRedacted,
                            onTap: onTaskTapped
                        )
                        if task != viewModel.tasksForDisplay.last {
                            StoreDivider()
                        }
                    }
                }

                if viewModel.shouldShowViewAllButton {
                    StoreDivider()
                        .padding(.leading, StorePadding.p5)
                    StoreDashboardCardFooterAction(
                        String.localizedStringWithFormat(Localization.viewAll, viewModel.taskViewModels.count),
                        textStyle: .titleMedium,
                        showsDisclosureIndicator: true,
                        action: showAllTasks
                    )
                }
            }
        }
    }

    private func reloadTasks() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .onboarding))
        Task {
            await viewModel.reloadTasks()
        }
    }

    private func showAllTasks() {
        onViewAllTapped(viewModel.taskViewModels)
    }
}

private extension StoreOnboardingDashboardCard {
    enum Localization {
        static let hide = NSLocalizedString(
            "storeOnboardingDashboardCard.hide",
            value: "Hide store setup list",
            comment: "Menu action that hides the Store Setup card from the dashboard."
        )
        static let viewAll = NSLocalizedString(
            "storeOnboardingDashboardCard.viewAll",
            value: "View all %1$d tasks",
            comment: "Action that opens all Store Setup tasks. %1$d is the total number of tasks."
        )
    }
}

#Preview("Store setup") {
    StoreOnboardingDashboardCard(
        viewModel: .preview(taskViewModels: [
            .init(task: .init(isComplete: true, type: .storeDetails)),
            .init(task: .init(isComplete: false, type: .addFirstProduct)),
            .init(task: .init(isComplete: false, type: .payments), badgeText: "Payments available"),
            .init(task: .init(isComplete: false, type: .launchStore))
        ]),
        onTaskTapped: { _ in },
        onViewAllTapped: { _ in }
    )
    .padding(StorePadding.p5)
    .background(Color.storeSurfaceDim)
}

#if DEBUG
extension StoreOnboardingViewModel {
    static func preview(taskViewModels: [StoreOnboardingTaskViewModel]) -> StoreOnboardingViewModel {
        let viewModel = StoreOnboardingViewModel(
            siteID: 0,
            isExpanded: false,
            taskViewModels: taskViewModels,
            analytics: MockAnalyticsPreview()
        )
        viewModel.update(state: .loaded(rows: taskViewModels))
        return viewModel
    }
}
#endif
