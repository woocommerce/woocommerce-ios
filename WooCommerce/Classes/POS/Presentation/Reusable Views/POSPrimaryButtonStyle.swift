import SwiftUI

struct POSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(minHeight: POSButtonStyleConstants.framedButtonMinHeight)
        .font(.posBodyEmphasized)
        .background(Color.posPrimaryButtonBackground)
        .foregroundColor(Color.white)
        .cornerRadius(POSButtonStyleConstants.framedButtonCornerRadius)
    }
}
