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
                    Button(ProgressLocalization.hideStoreSetupListButton, action: viewModel.hideTaskList)
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
    typealias Localization = StoreOnboardingView.Localization
    typealias ProgressLocalization = StoreSetupProgressView.Localization
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
