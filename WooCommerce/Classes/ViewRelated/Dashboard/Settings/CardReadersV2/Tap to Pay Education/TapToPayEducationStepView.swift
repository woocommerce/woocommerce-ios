import Foundation
import SwiftUI
import struct WooFoundation.ScrollableVStack

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
                .padding(.horizontal, Constants.horizontalPadding)
            Image(viewModel.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: Constants.maxImageHeight)
                .accessibilityHidden(true)
            Group {
                if viewModel.descriptionSteps.count > 1 {
                    ForEach(viewModel.descriptionSteps.indices, id: \.self) { index in
                        PaymentSettingsFlowHint(number: index + 1,
                                                text: viewModel.descriptionSteps[index])
                    }
                } else if let description = viewModel.descriptionSteps.first {
                    Text(description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)

            if let limit = viewModel.limit {
                TapToPayEducationContactlessLimitView(viewModel: limit)
                    .padding([.top, .bottom])
                    .padding(.horizontal, Constants.horizontalPadding)
            }

            Spacer(minLength: 0)
        }
        .padding([.top, .bottom], 0)
        .scrollIndicators(.hidden)
    }
}

private enum Constants {
    static let horizontalPadding: CGFloat = 24
    static let maxImageHeight: CGFloat = 350
}
