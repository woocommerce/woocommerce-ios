import SwiftUI

/// Displays a list of steps on how to print a shipping label on an iOS device.
struct ShippingLabelPrintingStepListView: View {
    var body: some View {
        VStack {
            ShippingLabelPrintingStepView(stepIndex: 1, text: Localization.step1, isLastStep: false)
            ShippingLabelPrintingStepView(stepIndex: 2, text: Localization.step2, isLastStep: false)
            ShippingLabelPrintingStepView(stepIndex: 3, text: Localization.step3, isLastStep: false)
            ShippingLabelPrintingStepView(stepIndex: 4, text: Localization.step4, isLastStep: true)
        }
    }
}

private extension ShippingLabelPrintingStepListView {
    enum Localization {
        static let step1 = NSLocalizedString(
            "Verify your printer and device are connected to the **same Wi-Fi network**.\n\n"
                + "Check your printer's documentation for information on connecting it to your Wi-Fi network.",
            comment: "Step 1 of shipping label printing instructions screen. The content inside two double asterisks **...** denote bolded text.")
        static let step2 = NSLocalizedString(
            "**Ensure AirPrint is enabled** in your printer settings. You may need to configure this setting on the printer itself.\n\n"
            + "See the documentation that came with your printer for details.",
            comment: "Step 2 of shipping label printing instructions screen. The content inside two double asterisks **...** denote bolded text.")
        static let step3 = NSLocalizedString(
            "Ensure that your **printer firmware is up to date**. See your printer documentation for instructions on updating.",
            comment: "Step 3 of shipping label printing instructions screen. The content inside two double asterisks **...** denote bolded text.")
        static let step4 = NSLocalizedString(
            "If you are still experiencing issues printing from your phone, you can save your label as PDF and **send it by email** "
            + "to print it from another device.",
            comment: "Step 4 of shipping label printing instructions screen. The content inside two double asterisks **...** denote bolded text.")
    }
}

// MARK: - Previews

#if DEBUG

struct ShippingLabelPrintingStepsView_Previews: PreviewProvider {
    static var previews: some View {
        ShippingLabelPrintingStepListView()
    }
}

#endif
