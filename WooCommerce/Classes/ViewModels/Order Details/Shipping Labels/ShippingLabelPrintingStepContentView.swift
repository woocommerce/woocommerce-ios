import SwiftUI

/// Displays a horizontal stack view with the step index followed by the instruction text for the step.
struct ShippingLabelPrintingStepContentView: View {
    private let stepIndex: Int
    private let text: String

    init(stepIndex: Int, text: String) {
        self.stepIndex = stepIndex
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Circle()
                .frame(width: 30, height: 30, alignment: .center)
                .foregroundColor(Color(UIColor.primary))
                .overlay(
                    Text("\(stepIndex)")
                        .foregroundColor(.white)
                )
            BoldableTextView(text)
        }
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPrintingStepContentView_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPrintingStepContentView(stepIndex: 6, text: "How to print a label")
    }
}

#endif
