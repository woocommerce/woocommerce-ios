import SwiftUI

struct POSSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(minHeight: POSButtonStyleConstants.framedButtonMinHeight)
        .font(.posBodyEmphasized)
        .background(
            RoundedRectangle(cornerRadius: POSButtonStyleConstants.framedButtonCornerRadius)
                .stroke(Color.posPrimaryButtonBackground,
                        lineWidth: POSButtonStyleConstants.secondaryButtonBorderStrokeWidth)
                .background(Color.posPrimaryBackground))
        .foregroundColor(.posPrimaryButtonBackground)
    }
}
