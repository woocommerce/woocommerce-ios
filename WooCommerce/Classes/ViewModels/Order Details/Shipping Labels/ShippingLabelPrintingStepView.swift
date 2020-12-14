import SwiftUI

/// Displays one of the steps on how to print a shipping label on an iOS device.
struct ShippingLabelPrintingStepView: View {
    private let stepIndex: Int
    private let text: String
    private let isLastStep: Bool

    init(stepIndex: Int,
         text: String,
         isLastStep: Bool) {
        self.stepIndex = stepIndex
        self.text = text
        self.isLastStep = isLastStep
    }

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
                .frame(height: 14)
            ShippingLabelPrintingStepContentView(stepIndex: stepIndex, text: text)
                .padding(.leading, 16)
                .padding(.trailing, 16)
            Spacer()
                .frame(height: 14)
            Divider().padding(.leading, isLastStep ? 0: 56)
        }
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPrintingStepView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ShippingLabelPrintingStepView(stepIndex: 1, text: "Hello", isLastStep: false)
            ShippingLabelPrintingStepView(stepIndex: 2, text: "Hello", isLastStep: true)
        }
    }
}

#endif
