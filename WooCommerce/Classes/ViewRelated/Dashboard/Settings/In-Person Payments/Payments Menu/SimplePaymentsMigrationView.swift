import SwiftUI

/// Shows information about the migration from simple payments to order creation in Menu tab > Payments > Collect Payment.
struct SimplePaymentsMigrationView: View {
    private let addCustomAmount: () -> Void

    init(addCustomAmount: @escaping () -> Void) {
        self.addCustomAmount = addCustomAmount
    }

    var body: some View {
        VStack(spacing: Layout.defaultVerticalSpacing) {
            VStack(spacing: Layout.verticalSpacingBetweenElements) {
                Image(uiImage: .bell)
                Text(Localization.title)
                    .titleStyle()
                    .bold()
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: Layout.verticalSpacingBetweenElements) {
                // The subtitle is in an `.init` in order to support markdown.
                Text(.init(Localization.subtitle))
                    .bodyStyle()
                Text(Localization.detail)
                    .foregroundColor(Color(.secondaryLabel))
                    .bodyStyle()
            }
            Button(Localization.addCustomAmount) {
                addCustomAmount()
                ServiceLocator.analytics.track(event: .SimplePayments.simplePaymentsMigrationSheetAddCustomAmount())
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, Layout.extraButtonTopPadding)
            .accessibilityIdentifier("simple-payments-migration-add-custom-amount")
        }
        .multilineTextAlignment(.center)
        .padding(Layout.padding)
        .onAppear {
            ServiceLocator.analytics.track(event: .SimplePayments.simplePaymentsMigrationSheetShown())
        }
    }
}

private extension SimplePaymentsMigrationView {
    enum Localization {
        static let title = NSLocalizedString(
            "simplePaymentsMigrationSheet.title",
            value: "Collect Payment has moved",
            comment: "Title for the simple payments migration view."
        )
        static let subtitle = NSLocalizedString(
            "simplePaymentsMigrationSheet.subtitle",
            value: "We’ve combined payment collection with order creation, making it more accessible *and* more powerful.",
            comment: "Title for the simple payments migration view. Text in the asterisks is italic."
        )
        static let detail = NSLocalizedString(
            "simplePaymentsMigrationSheet.detail",
            value: "To set a payment amount, add a custom amount to your new order.",
            comment: "Detail for the simple payments migration view."
        )
        static let addCustomAmount = NSLocalizedString(
            "simplePaymentsMigrationSheet.addCustomAmount",
            value: "Add a Custom Amount",
            comment: "Action to add a custom amount in the simple payments migration view."
        )
    }

    enum Layout {
        static let padding = EdgeInsets(top: 27, leading: 16, bottom: 16, trailing: 16)
        static let defaultVerticalSpacing: CGFloat = 16
        static let verticalSpacingBetweenElements: CGFloat = 24
        static let extraButtonTopPadding: CGFloat = 24
    }
}

struct SimplePaymentsMigrationView_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .sheet(isPresented: .constant(true)) {
                SimplePaymentsMigrationView {}
                    .presentationDetents([.medium, .large])
            }
    }
}
