import SwiftUI

struct POSTertiaryButtonStyle: ButtonStyle {
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
                .stroke(Color.posPrimaryText,
                        lineWidth: POSButtonStyleConstants.tertiaryButtonBorderStrokeWidth))
        .foregroundColor(.posPrimaryText)
    }
}
