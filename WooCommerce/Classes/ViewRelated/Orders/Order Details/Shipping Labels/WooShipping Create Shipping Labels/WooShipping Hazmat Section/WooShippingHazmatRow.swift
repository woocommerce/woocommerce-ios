import SwiftUI

struct WooShippingHazmatRow: View {
    /// Whether the interactions (navigation/setting selection) are enabled.
    private let enabled: Bool

    @Binding private var isHazardous: Bool

    @Binding private var selectedCategory: ShippingLabelHazmatCategory?

    @State private var isShowingDetailView = false

    init(isHazardous: Binding<Bool>,
         selectedCategory: Binding<ShippingLabelHazmatCategory?>,
         enabled: Bool) {
        self._isHazardous = isHazardous
        self._selectedCategory = selectedCategory
        self.enabled = enabled
    }

    var body: some View {
        Button(action: {
            isShowingDetailView = true
        }) {
            AdaptiveStack {
                Text(Localization.hazmatLabel)
                    .bodyStyle()
                Spacer()
                Text(isHazardous ? Localization.yes : Localization.no)
                    .secondaryBodyStyle()
                Image(uiImage: .chevronImage)
                    .secondaryBodyStyle()
                    .renderedIf(enabled)
            }
            .padding(.vertical, Layout.verticalPadding)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .sheet(isPresented: $isShowingDetailView) {
            WooShippingHazmatDetailView(isHazardous: $isHazardous,
                                        selectedCategory: $selectedCategory)
        }
    }
}

private extension WooShippingHazmatRow {
    enum Layout {
        static let backgroundRadius: CGFloat = 8
        static let verticalPadding: CGFloat = 24
    }

    enum Localization {
        static let hazmatLabel = NSLocalizedString("wooShipping.createLabel.hazmatRow.label",
                                                   value: "Are you shipping dangerous goods or hazardous materials?",
                                                   comment: "Label for section in shipping label creation to declare when a package contains hazardous materials.")
        static let yes = NSLocalizedString(
            "wooShipping.createLabel.hazmatRow.yes",
            value: "Yes",
            comment: "Value for section in shipping label creation to declare when a package contains hazardous materials."
        )
        static let no = NSLocalizedString(
            "wooShipping.createLabel.hazmatRow.no",
            value: "No",
            comment: "Value for section in shipping label creation to declare when a package does not contain hazardous materials."
        )
    }
}

#Preview {
    WooShippingHazmatRow(isHazardous: .constant(false),
                         selectedCategory: .constant(nil),
                         enabled: true)
        .padding()
}
