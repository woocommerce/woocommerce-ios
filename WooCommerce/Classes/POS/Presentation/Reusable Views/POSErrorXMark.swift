import SwiftUI

struct POSErrorXMark: View {
    var body: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.system(size: PointOfSaleCardPresentPaymentLayout.largeErrorIconSize))
            .foregroundStyle(Color(.wooCommerceAmber(.shade60)))
            .accessibilityHidden(true)
    }
}

#Preview {
    POSErrorXMark()
}
