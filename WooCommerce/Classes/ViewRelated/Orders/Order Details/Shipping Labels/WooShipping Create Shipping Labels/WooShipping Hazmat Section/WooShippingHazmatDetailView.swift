import SwiftUI

struct WooShippingHazmatDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding private var isHazardous: Bool

    init(isHazardous: Binding<Bool>) {
        self._isHazardous = isHazardous
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Button(Localization.cancel) {
                        dismiss()
                    }
                    .padding(.vertical)
                    Spacer()
                }

                Text(Localization.title)
                    .secondaryTitleStyle()
                    .bold()

                Toggle(isOn: $isHazardous) {
                    Text(Localization.toggleLabel)
                }
                .padding()

                Button(Localization.selectCategory) {
                    // TODO: navigate to category list
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom)
                .renderedIf(isHazardous)

                Divider()

                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

private extension WooShippingHazmatDetailView {
    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingHazmatDetailView.title",
            value: "Are you shipping dangerous goods or hazardous materials?",
            comment: "Title of the HAZMAT detail view in the shipping label creation flow"
        )
        static let cancel = NSLocalizedString(
            "wooShippingHazmatDetailView.cancel",
            value: "Cancel",
            comment: "Button to dismiss the HAZMAT detail view in the shipping label creation flow"
        )
        static let toggleLabel = NSLocalizedString(
            "wooShippingHazmatDetailView.switchLabel",
            value: "Contains hazardous materials",
            comment: "Label of the toggle on the HAZMAT detail view in the shipping label creation flow"
        )
        static let selectCategory = NSLocalizedString(
            "wooShippingHazmatDetailView.selectCategory",
            value: "Select Category",
            comment: "Button to select hazardous material category on the HAZMAT detail view in the shipping label creation flow"
        )
    }
}

#Preview {
    WooShippingHazmatDetailView(isHazardous: .constant(true))
}
