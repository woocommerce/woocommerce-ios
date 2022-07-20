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
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 1)
                .background(Color(.tertiarySystemBackground))
               )
        .accessibilityElement(children: .combine)
                .accessibilityLabel(name)
                .accessibilityRemoveTraits([.isImage])
                .accessibilityAddTraits([.isButton])
                .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
    var borderColor: Color {
        if selected {
            return Color(.primary)
        } else {
            return Color(.tertiaryLabel)
        }
    }
}

struct InPersonPaymentsSelectPluginView: View {
    @State var selectedPlugin: CardPresentPaymentsPlugin?
    let onPluginSelected: (CardPresentPaymentsPlugin) -> Void

    var body: some View {
        ScrollableVStack(padding: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Image(uiImage: .creditCardGiveIcon)
                    .foregroundColor(Color(.primary))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 32) {
                    Text(Localization.title)
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Localization.prompt)
                        .fixedSize(horizontal: false, vertical: true)
                        .bodyStyle()

                    VStack(alignment: .leading, spacing: 16) {
                        InPersonPaymentsSelectPluginRow(icon: .wcpayIcon, name: "WooCommerce Payments", selected: selectedPlugin == .wcPay)
                            .onTapGesture {
                                selectedPlugin = .wcPay
                            }
                        InPersonPaymentsSelectPluginRow(icon: .stripeIcon, name: "Stripe", selected: selectedPlugin == .stripe)
                            .onTapGesture {
                                selectedPlugin = .stripe
                            }
                    }
                }

                Spacer()

                Button(Localization.confirm, action: confirmPluginSelection)
                .disabled(selectedPlugin == nil)
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top, 32)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .background(Color(.tertiarySystemBackground).ignoresSafeArea())
        }
    }

    private func confirmPluginSelection() {
        guard let selectedPlugin = selectedPlugin else {
            // This should not be possible
            assertionFailure()
            return DDLogError("Attempt to confirm a payment gateway selection with no gateway selected")
        }
        onPluginSelected(selectedPlugin)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Choose your Payment Provider",
        comment: "Title for the screen to select the preferred provider for In-Person Payments")
    static let prompt = NSLocalizedString(
        "In-Person Payments can be processed through either of these payment providers. Which provider would you like to use?",
        comment: "Main prompt for the screen to select the preferred provider for In-Person Payments")
    static let confirm = NSLocalizedString(
        "Confirm Payment Method",
        comment: "Button to confirm the preferred provider for In-Person Payments")
}

struct InPersonPaymentsSelectPlugin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsSelectPluginView(onPluginSelected: { _ in })
        InPersonPaymentsSelectPluginView(selectedPlugin: .wcPay, onPluginSelected: { _ in })
        InPersonPaymentsSelectPluginView(selectedPlugin: .stripe, onPluginSelected: { _ in })
            .preferredColorScheme(.dark)
    }
}
