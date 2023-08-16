import SwiftUI

/// Necessary data from the answer to the store creation selling status question.
struct StoreCreationSellingStatusAnswer: Equatable {
    /// The status of the merchant's eCommerce experience.
    let sellingStatus: StoreCreationSellingStatusQuestionViewModel.SellingStatus
    /// The eCommerce platforms that the merchant is already selling on.
    /// When the merchant isn't already selling online, the value is `nil`.
    let sellingPlatforms: Set<StoreCreationSellingPlatformsQuestionViewModel.Platform>?
}

/// Displays the selling status question initially. If the user chooses the "I'm already selling online" option, the selling
/// platforms question is shown.
struct StoreCreationSellingStatusQuestionContainerView: View {
    @StateObject private var viewModel: StoreCreationSellingStatusQuestionViewModel
    private let onContinue: (StoreCreationSellingStatusAnswer?) -> Void

    init(onContinue: @escaping (StoreCreationSellingStatusAnswer?) -> Void, onSkip: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: StoreCreationSellingStatusQuestionViewModel(onContinue: onContinue, onSkip: onSkip))
        self.onContinue = onContinue
    }

    var body: some View {
        if viewModel.isAlreadySellingOnline {
            StoreCreationSellingPlatformsQuestionView(onContinue: onContinue)
        } else {
            StoreCreationSellingStatusQuestionView(viewModel: viewModel)
        }
    }
}

struct StoreCreationSellingStatusQuestionContainerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreCreationSellingStatusQuestionContainerView(onContinue: { _ in }, onSkip: {})
        }
    }
}
