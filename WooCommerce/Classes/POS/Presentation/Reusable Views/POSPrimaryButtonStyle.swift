import SwiftUI

struct POSPrimaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(minHeight: POSButtonStyleConstants.framedButtonMinHeight)
        .font(.posBodyEmphasized)
        .background(Color.posPrimaryButtonBackground)
        .foregroundColor(colorScheme == .light ? Color.white : Color.black)
        .cornerRadius(POSButtonStyleConstants.framedButtonCornerRadius)
    }
}
