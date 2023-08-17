import SwiftUI

/// Shows the store features question in the store creation flow.
struct StoreCreationFeaturesQuestionView: View {
    @ObservedObject private var viewModel: StoreCreationFeaturesQuestionViewModel

    init(viewModel: StoreCreationFeaturesQuestionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        OptionalStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.features, id: \.self) { feature in
                    Button(action: {
                        viewModel.didTapFeature(feature)
                    }, label: {
                        HStack {
                            Text(feature.name)
                            Spacer()
                        }
                    })
                    .buttonStyle(SelectableSecondaryButtonStyle(isSelected: viewModel.selectedFeatures.contains(where: { $0 == feature })))
                }
            }
        }
    }
}

struct StoreCreationFeaturesQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        StoreCreationFeaturesQuestionView(viewModel: .init(onContinue: { _ in },
                                                             onSkip: {}))
    }
}
