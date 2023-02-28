import SwiftUI

/// Shows a list of onboarding tasks for store setup with completion state.
struct StoreOnboardingView: View {
    private let viewModel: StoreOnboardingViewModel
    private let taskTapped: (StoreOnboardingTask) -> Void
    private let viewAllTapped: (() -> Void)?
    private let dismissAction: (() -> Void)?

    init(viewModel: StoreOnboardingViewModel,
         taskTapped: @escaping (StoreOnboardingTask) -> Void,
         viewAllTapped: (() -> Void)? = nil,
         dismissAction: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.taskTapped = taskTapped
        self.viewAllTapped = viewAllTapped
        self.dismissAction = dismissAction
    }

    var body: some View {
        VStack {
            Color(.systemColor(.systemGray6))
                .frame(height: 16)
                .renderedIf(!viewModel.isExpanded)

            let verticalSpacing = viewModel.isExpanded ? Layout.VerticalSpacing.expandedMode : Layout.VerticalSpacing.collapsedMode
            VStack(alignment: viewModel.isExpanded ? .center : .leading, spacing: verticalSpacing) {
                DismissButton(action: dismissAction)
                    .renderedIf(viewModel.isExpanded)

                // Progress view
                StoreSetupProgressView(isExpanded: viewModel.isExpanded,
                                       totalNumberOfTasks: viewModel.taskViewModels.count,
                                       numberOfTasksCompleted: viewModel.numberOfTasksCompleted)

                // Task list
                VStack(alignment: .leading, spacing: Layout.verticalSpacingBetweenTasks) {
                    ForEach(Array(viewModel.tasksForDisplay.enumerated()), id: \.offset) { index, taskViewModel in
                        let isLastTask = index == viewModel.tasksForDisplay.count - 1

                        StoreOnboardingTaskView(viewModel: taskViewModel,
                                                showDivider: !isLastTask) { task in
                            taskTapped(task)
                        }
                    }
                }

                // View all button
                ViewAllButton(action: viewAllTapped, text: String(format: Localization.viewAll, viewModel.taskViewModels.count))
                    .renderedIf(!viewModel.isExpanded)

                Spacer()
                    .renderedIf(viewModel.isExpanded)
            }
            .padding(insets: Layout.insets)
            .background(Color(uiColor: .listForeground(modal: false)))

            Color(.systemColor(.systemGray6))
                .frame(height: 16)
                .renderedIf(!viewModel.isExpanded)
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

private struct DismissButton: View {
    let action: (() -> Void)?

    var body: some View {
        HStack {
            Spacer()

            Button {
                action?()
            } label: {
                Image(uiImage: .closeButton)
                    .foregroundColor(Color(.gray(.shade30)))
            }
        }
    }
}

private struct ViewAllButton: View {
    let action: (() -> Void)?
    let text: String

    var body: some View {
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

struct StoreOnboardingCardView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingView(viewModel: .init(isExpanded: false), taskTapped: { _ in })

        StoreOnboardingView(viewModel: .init(isExpanded: true), taskTapped: { _ in })
    }
}
