import SwiftUI

struct StoreOnboardingView: View {
    private let viewModel: StoreOnboardingViewModel

    init(viewModel: StoreOnboardingViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ForEach(viewModel.taskViewModels, id: \.task) { taskViewModel in
                StoreOnboardingTaskView(viewModel: taskViewModel)
            }
        }
    }
}

struct StoreOnboardingCardView_Previews: PreviewProvider {
    static var previews: some View {
        StoreOnboardingView(viewModel: .init(isExpanded: false))
    }
}
