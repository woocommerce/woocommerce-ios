import SwiftUI

struct POSBookingBadgeView: View {
    let title: String
    let textColor: Color
    let backgroundColor: Color

    var body: some View {
        Text(title)
            .font(.posCaptionRegular)
            .foregroundStyle(textColor)
            .padding(.horizontal, POSPadding.small)
            .padding(.vertical, POSPadding.xSmall)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value))
    }
}
