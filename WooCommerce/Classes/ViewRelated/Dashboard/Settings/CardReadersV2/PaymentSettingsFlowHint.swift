import SwiftUI

struct PaymentSettingsFlowHint: View {
    let title: String
    let text: String

    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .padding(.all, 12)
                .background(Color(UIColor.systemGray6))
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
            PaymentSettingsFlowHint(title: "0", text: "This is some text that acts as a hint.")
            PaymentSettingsFlowHint(title: "1", text: "This is a hint in Dark Mode.")
                .preferredColorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
