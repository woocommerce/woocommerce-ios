import SwiftUI

struct POSPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
            Spacer()
        }
        .frame(minHeight: Constants.minButtonHeight)
        .font(.system(.title2, weight: .bold))
        .background(Color.posPrimaryButtonBackground)
        .foregroundColor(Color.white)
        .cornerRadius(Constants.cornerRadius)
    }
}

private extension POSPrimaryButtonStyle {
    enum Constants {
        static let minButtonHeight: CGFloat = 80
        static let cornerRadius: CGFloat = 8.0
    }
}
