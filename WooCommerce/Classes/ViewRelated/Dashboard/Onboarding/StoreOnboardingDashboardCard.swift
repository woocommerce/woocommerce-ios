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
                                     showsError: viewModel.failedToLoadTasks) {
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
                    StoreDashboardCardFooterAction(
                        String.localizedStringWithFormat(Localization.viewAll, viewModel.taskViewModels.count),
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
