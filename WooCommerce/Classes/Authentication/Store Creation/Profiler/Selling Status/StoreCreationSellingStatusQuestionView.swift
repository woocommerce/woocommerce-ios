import SwiftUI

/// Shows the store selling status question in the store creation flow.
struct StoreCreationSellingStatusQuestionView: View {
    @ObservedObject private var viewModel: StoreCreationSellingStatusQuestionViewModel

    init(viewModel: StoreCreationSellingStatusQuestionViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        OptionalStoreCreationProfilerQuestionView(viewModel: viewModel) {
            VStack(spacing: 16) {
                ForEach(viewModel.sellingStatuses, id: \.self) { sellingStatus in
                    Button(action: {
                        viewModel.selectStatus(sellingStatus)
                    }, label: {
                        HStack {
                            Text(sellingStatus.description)
                            Spacer()
                        }
                    })
                    .buttonStyle(SelectableSecondaryButtonStyle(isSelected: viewModel.selectedStatus == sellingStatus))
                }
            }
        }
    }
}

struct StoreCreationSellingStatusQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StoreCreationSellingStatusQuestionView(viewModel: .init(storeName: "New Year Store", onContinue: { _ in }, onSkip: {}))
        }
    }
}
