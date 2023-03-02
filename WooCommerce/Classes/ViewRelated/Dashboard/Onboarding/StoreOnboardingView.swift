import SwiftUI

/// Shows a list of onboarding tasks for store setup with completion state.
struct StoreOnboardingView: View {
    private let viewModel: StoreOnboardingViewModel
    private let taskTapped: (StoreOnboardingTask) -> Void
    private let viewAllTapped: (() -> Void)?

    init(viewModel: StoreOnboardingViewModel,
         taskTapped: @escaping (StoreOnboardingTask) -> Void,
         viewAllTapped: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.taskTapped = taskTapped
        self.viewAllTapped = viewAllTapped
    }

    var body: some View {
        VStack(alignment: viewModel.isExpanded ? .center : .leading, spacing: Layout.verticalSpacing) {
            // Progress view
            StoreSetupProgressView(isExpanded: viewModel.isExpanded,
                                   totalNumberOfTasks: viewModel.taskViewModels.count,
                                   numberOfTasksCompleted: viewModel.numberOfTasksCompleted)

            // Task list
            VStack(alignment: .leading, spacing: Layout.verticalSpacingBetweenTasks) {
                ForEach(Array(viewModel.taskViewModels.enumerated()), id: \.offset) { index, taskViewModel in
                    let isLastTask = index == viewModel.taskViewModels.count - 1

                    StoreOnboardingTaskView(viewModel: taskViewModel,
                                            showDivider: !isLastTask) { task in
                        taskTapped(task)
                    }
                }
            }

            // View all button
            Button {
                viewAllTapped?()
            } label: {
                Text(String(format: Localization.viewAll, viewModel.taskViewModels.count))
                    .fontWeight(.semibold)
                    .foregroundColor(.init(uiColor: .accent))
                    .subheadlineStyle()
            }
            .renderedIf(!viewModel.isExpanded)
        }
        .padding(.horizontal, insets: Layout.insets)
    }
}

private extension StoreOnboardingView {
    enum Layout {
        static let insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let verticalSpacing: CGFloat = 16
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
        StoreOnboardingView(viewModel: .init(isExpanded: false), taskTapped: { _ in })

        StoreOnboardingView(viewModel: .init(isExpanded: true), taskTapped: { _ in })
    }
}
