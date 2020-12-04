import SwiftUI

/// Displays one of the steps on how to print a shipping label on an iOS device.
struct ShippingLabelPrintingStepView: View {
    struct ViewModel {
        let stepIndex: Int
        let text: String
        let isLastStep: Bool
    }

    private let viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
                .frame(height: 14)
            HStack(alignment: .top, spacing: 11) {
                Circle()
                    .frame(width: 30, height: 30, alignment: .center)
                    .foregroundColor(Color(UIColor.primary))
                    .overlay(
                        Text("\(viewModel.stepIndex)")
                            .foregroundColor(.white)
                    )
                BoldableTextView(viewModel.text)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            Spacer()
                .frame(height: 14)
            Divider().padding(.leading, viewModel.isLastStep ? 0: 56)
        }
    }
}

struct ShippingLabelPrintingStepView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ShippingLabelPrintingStepView(viewModel: .init(stepIndex: 1, text: "Hello", isLastStep: false))
            ShippingLabelPrintingStepView(viewModel: .init(stepIndex: 2, text: "Hello", isLastStep: true))
        }
    }
}
