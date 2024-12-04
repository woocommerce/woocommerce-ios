import SwiftUI

struct PaymentSettingsFlowHint: View {
    let number: Int
    let text: String

    var body: some View {
        HStack {
            Text(number, format: .number)
                .font(.callout)
                .padding(.all, 12)
                .background(Color(.init(light: .systemGray6, dark: .darkGray)))
                .clipShape(Circle())
            Text(text)
                .font(.callout)
                .padding(.leading, 16)
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

struct PaymentSettingsFlowHint_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentSettingsFlowHint(number: 0, text: "This is some text that acts as a hint.")
            PaymentSettingsFlowHint(number: 1, text: "This is a hint in Dark Mode.")
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
