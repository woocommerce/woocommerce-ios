import Foundation
import SwiftUI

struct TapToPayEducationStepView: View {
    private let viewModel: TapToPayEducationStepViewModel

    init(viewModel: TapToPayEducationStepViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollableVStack(padding: 0, spacing: 8) {
            Text(viewModel.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)
            Image(viewModel.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 350)
            if viewModel.descriptionSteps.count > 1 {
                ForEach(viewModel.descriptionSteps.indices, id: \.self) { index in
                    PaymentSettingsFlowHint(number: index + 1,
                                            text: viewModel.descriptionSteps[index])
                }
            } else if let description = viewModel.descriptionSteps.first {
                Text(description)
                    .font(.body)
            }

            if let limit = viewModel.limit {
                AboutTapToPayContactlessLimitView(viewModel: limit)
                    .padding([.top, .bottom])
            }

            Spacer(minLength: 0)
        }
        .padding([.leading, .trailing], 24)
        .padding([.top, .bottom], 0)
        .scrollIndicators(.hidden)
    }
}
