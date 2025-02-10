import SwiftUI

struct POSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(minHeight: POSButtonStyleConstants.framedButtonMinHeight)
        .font(.posBodyLargeEmphasized)
        .background(
            RoundedRectangle(cornerRadius: POSButtonStyleConstants.framedButtonCornerRadius)
                .stroke(Color.posSecondaryButtonForeground,
                        lineWidth: POSButtonStyleConstants.secondaryButtonBorderStrokeWidth)
                .background(Color.posSurface))
        .foregroundColor(.posSecondaryButtonForeground)
    }
}
