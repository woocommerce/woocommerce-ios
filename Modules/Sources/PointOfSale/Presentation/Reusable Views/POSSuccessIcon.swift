import SwiftUI

struct POSSuccessIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundColor(.posSuccess)
            PointOfSaleAssets.successCheck.image
                .renderingMode(.template)
                .foregroundColor(.posOnSuccess)
                .frame(width: Constants.checkmarkSize)
                .accessibilityHidden(true)
        }
    }
}

private extension POSSuccessIcon {
    enum Constants {
        static let iconSize: CGFloat = 165
        static let checkmarkSize: CGFloat = 52
    }
}

#if DEBUG
#Preview {
    POSSuccessIcon()
}
#endif
