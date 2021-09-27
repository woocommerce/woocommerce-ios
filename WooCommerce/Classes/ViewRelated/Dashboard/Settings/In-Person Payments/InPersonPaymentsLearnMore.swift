import SwiftUI

struct InPersonPaymentsLearnMore: View {
    @Environment(\.customOpenURL) var customOpenURL

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Image(uiImage: .infoOutlineImage)
                .resizable()
                .foregroundColor(Color(.textSubtle))
                .frame(width: iconSize, height: iconSize)
            Text(Localization.learnMore)
                .font(.subheadline)
        }
    }

    var iconSize: CGFloat {
        UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 20)
    }
}

private enum Localization {
    static let unavailable = NSLocalizedString(
        "In-Person Payments is currently unavailable",
        comment: "Title for the error screen when In-Person Payments is unavailable"
    )

    static let acceptCash = NSLocalizedString(
        "You can still accept in-person cash payments by enabling the “Cash on Delivery” payment method on your store.",
        comment: "Generic error message when In-Person Payments is unavailable"
    )

    static let learnMore = NSLocalizedString(
        "Visit woocommerce.com/payments to learn more about accepting payments with your mobile device and ordering card readers",
        comment: "Generic error message when In-Person Payments is unavailable"
    )
}

struct InPersonPaymentsLearnMore_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLearnMore()
            .padding()
    }
}
