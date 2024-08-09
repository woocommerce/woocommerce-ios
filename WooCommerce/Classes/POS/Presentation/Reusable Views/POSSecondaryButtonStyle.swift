import SwiftUI

struct POSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(minHeight: POSButtonStyleConstants.framedButtonMinHeight)
        .font(.system(.title2, weight: .bold))
        .background(
            RoundedRectangle(cornerRadius: POSButtonStyleConstants.framedButtonCornerRadius)
                .stroke(Color.posSecondaryButtonTint,
                        lineWidth: POSButtonStyleConstants.secondaryButtonBorderStrokeWidth)
                .background(Color.posSecondaryButtonBackground))
        .foregroundColor(.posSecondaryButtonTint)
    }
}
