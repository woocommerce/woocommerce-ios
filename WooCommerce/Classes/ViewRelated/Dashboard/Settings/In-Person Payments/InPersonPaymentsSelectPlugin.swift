import SwiftUI
import Yosemite

struct InPersonPaymentsSelectPluginRow: View {
    let icon: UIImage
    let name: String
    let selected: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: icon)
            Text(name)
                .headlineStyle()
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if selected {
                Image(systemName: "checkmark")
                    .foregroundColor(Color(.primary))
            } else {
                Color.clear.frame(width: 24, height: 24, alignment: .center)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.primary), lineWidth: 1)
               )
    }
}

struct InPersonPaymentsSelectPlugin: View {
    @State var selectedPlugin: CardPresentPaymentsPlugin?

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 24) {
                Image(uiImage: .creditCardGiveIcon)
                    .foregroundColor(Color(.primary))

                Text(Localization.title)
                    .font(.largeTitle.bold())
                Text(Localization.prompt)
                    .bodyStyle()
                Text(Localization.notice)
                    .font(.caption)
                    .foregroundColor(Color(.text))

                InPersonPaymentsSelectPluginRow(icon: .wcpayIcon, name: "WooCommerce Payments", selected: selectedPlugin == .wcPay)
                    .onTapGesture {
                        selectedPlugin = .wcPay
                    }
                InPersonPaymentsSelectPluginRow(icon: .stripeIcon, name: "Stripe", selected: selectedPlugin == .stripe)
                    .onTapGesture {
                        selectedPlugin = .stripe
                    }
            }
            .padding(40)

            // TODO: Localize
            Button("Continue") {
                // TODO
            }
            .disabled(selectedPlugin == nil)
            .padding(.horizontal, 16)
            .padding(.bottom, 42)
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Choose your Payment Provider",
        comment: "Title for the screen to select the preferred provider for In-Person Payments")
    static let prompt = NSLocalizedString(
        "In-Person Payments will only work with one provider activated. Which provider would you like to use?",
        comment: "Main prompt for the screen to select the preferred provider for In-Person Payments")
    static let notice = NSLocalizedString(
        "The provider that you don’t choose will be deactivated.",
        comment: "Explanation for the screen to select the preferred provider for In-Person Payments")
}

struct InPersonPaymentsSelectPlugin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsSelectPlugin()
    }
}
