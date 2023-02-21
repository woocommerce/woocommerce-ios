import SwiftUI

/// Shows a list of onboarding tasks for store setup with completion state.
struct StoreOnboardingView: View {
    private let viewModel: StoreOnboardingViewModel
    private let taskTapped: (StoreOnboardingTask) -> Void

    init(viewModel: StoreOnboardingViewModel, taskTapped: @escaping (StoreOnboardingTask) -> Void) {
        self.viewModel = viewModel
        self.taskTapped = taskTapped
    }

    var body: some View {
        VStack {
            ForEach(viewModel.taskViewModels, id: \.task) { taskViewModel in
                StoreOnboardingTaskView(viewModel: taskViewModel) { task in
                    taskTapped(task)
                }
            }
        }
    }
}

struct StoreOnboardingCardView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingView(viewModel: .init(isExpanded: false), taskTapped: { _ in })
    }
}
