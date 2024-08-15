import SwiftUI

struct POSErrorExclamationMark: View {
    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: PointOfSaleCardPresentPaymentLayout.errorIconSize))
            .foregroundStyle(Color(.wooCommerceAmber(.shade60)))
    }
}

#Preview {
    POSErrorExclamationMark()
}
