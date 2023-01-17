import SwiftUI

/// Shows the followup question to the store selling status question in the store creation flow, for users who are already online.
/// Displays a list of eCommerce platforms for the user to choose the ones they're already selling on.
struct StoreCreationSellingPlatformsQuestionView: View {
    @ObservedObject private var viewModel: StoreCreationSellingPlatformsQuestionViewModel

    init(storeName: String, onContinue: @escaping (StoreCreationSellingStatusAnswer?) -> Void, onSkip: @escaping () -> Void) {
        self.viewModel = StoreCreationSellingPlatformsQuestionViewModel(storeName: storeName, onContinue: onContinue, onSkip: onSkip)
    }

    var body: some View {
        OptionalStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(spacing: 16) {
                ForEach(viewModel.platforms, id: \.self) { platform in
                    Button(action: {
                        viewModel.selectPlatform(platform)
                    }, label: {
                        HStack {
                            Text(platform.description)
                            Spacer()
                        }
                    })
                    .buttonStyle(SelectableSecondaryButtonStyle(isSelected: viewModel.selectedPlatforms.contains(platform)))
                }
            }
        }
    }
}

struct StoreCreationSellingPlatformsQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreCreationSellingPlatformsQuestionView(storeName: "New Year Store", onContinue: { _ in }, onSkip: {})
        }
    }
}
