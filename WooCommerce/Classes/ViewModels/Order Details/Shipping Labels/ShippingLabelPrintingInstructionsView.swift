import SwiftUI

/// Displays an illustration at the top and four steps on how to print a shipping label on an iOS device.
struct ShippingLabelPrintingInstructionsView: View {
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                    .frame(height: 20)
                Image("woo-shipping-label-printing-instructions")
                Spacer()
                    .frame(height: 30)
                ShippingLabelPrintingStepListView()
            }
        }.background(Color(UIColor.basicBackground))
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPrintingInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShippingLabelPrintingInstructionsView()
                .environment(\.colorScheme, .light)
            ShippingLabelPrintingInstructionsView()
                .environment(\.colorScheme, .dark)
            ShippingLabelPrintingInstructionsView()
                .environment(\.colorScheme, .dark)
                .previewLayout(.fixed(width: 715, height: 320))
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .compact)
        }
    }
}

#endif
