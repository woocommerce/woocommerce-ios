import SwiftUI

/// Shows information about the migration from simple payments to order creation in Menu tab > Payments > Collect Payment.
struct SimplePaymentsMigrationView: View {
    let addCustomAmount: () -> Void

    var body: some View {
        VStack(spacing: Layout.defaultVerticalSpacing) {
            Spacer()
                .frame(height: 8)
            Image(uiImage: .bell)
            Text(Localization.title)
                .titleStyle()
                .bold()
                .fixedSize(horizontal: false, vertical: true)
            Text(.init(Localization.subtitle))
                .bodyStyle()
            Text(Localization.detail)
                .foregroundColor(Color(.secondaryLabel))
                .bodyStyle()
            Spacer()
                .frame(height: 24)
            Button(Localization.addCustomAmount) {
                addCustomAmount()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .multilineTextAlignment(.center)
        .padding(Layout.padding)
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
            value: " We’ve combined payment collection with order creation, making it more accessible *and* more powerful.",
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
        static let padding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let defaultVerticalSpacing: CGFloat = 16
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
