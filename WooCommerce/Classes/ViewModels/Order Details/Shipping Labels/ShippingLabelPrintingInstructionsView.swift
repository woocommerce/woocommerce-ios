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
                ShippingLabelPrintingStepView(viewModel: .init(stepIndex: 1, text: Localization.step1, isLastStep: false))
                ShippingLabelPrintingStepView(viewModel: .init(stepIndex: 2, text: Localization.step2, isLastStep: false))
                ShippingLabelPrintingStepView(viewModel: .init(stepIndex: 3, text: Localization.step3, isLastStep: false))
                ShippingLabelPrintingStepView(viewModel: .init(stepIndex: 4, text: Localization.step4, isLastStep: true))
            }
        }.background(Color(UIColor.basicBackground))
    }
}

private extension ShippingLabelPrintingInstructionsView {
    enum Localization {
        static let step1 = NSLocalizedString(
            "Verify your printer and device are connected to the *same Wi-Fi network*.\n\n"
                + "Check your printer's documentation for information on connecting it to your Wi-Fi network.",
            comment: "Step 1 of shipping label printing instructions screen. The content inside two asterisks *...* denote bolded text.")
        static let step2 = NSLocalizedString(
            "*Ensure AirPrint is enabled* in your printer settings. You may need to configure this setting on the printer itself.\n\n"
            + "See the documentation that came with your printer for details.",
            comment: "Step 2 of shipping label printing instructions screen. The content inside two asterisks *...* denote bolded text.")
        static let step3 = NSLocalizedString(
            "Ensure that your *printer firmware is up to date*. See your printer documentation for instructions on updating.",
            comment: "Step 2 of shipping label printing instructions screen. The content inside two asterisks *...* denote bolded text.")
        static let step4 = NSLocalizedString(
            "If you are still experiencing issues printing from your phone, you can save your label as PDF and *send it by email* "
            + "to print it from another device.",
            comment: "Step 2 of shipping label printing instructions screen. The content inside two asterisks *...* denote bolded text.")
    }
}

struct ShippingLabelPrintingInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ShippingLabelPrintingInstructionsView()
                .environment(\.colorScheme, .light)
            ShippingLabelPrintingInstructionsView()
                .environment(\.colorScheme, .dark)
        }
    }
}
