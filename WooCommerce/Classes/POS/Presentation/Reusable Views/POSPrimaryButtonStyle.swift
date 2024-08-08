import SwiftUI

struct POSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(minHeight: POSButtonStyleConstants.framedButtonMinHeight)
        .font(.system(.title2, weight: .bold))
        .background(Color.posPrimaryButtonBackground)
        .foregroundColor(Color.white)
        .cornerRadius(POSButtonStyleConstants.framedButtonCornerRadius)
    }
}
