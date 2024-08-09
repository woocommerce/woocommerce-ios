import SwiftUI

struct POSErrorExclamationMark: View {
    var body: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .font(.system(size: PointOfSaleCardPresentPaymentLayout.errorIconSize))
            .foregroundStyle(Color.wooAmberShade60)
    }
}

#Preview {
    POSErrorExclamationMark()
}
