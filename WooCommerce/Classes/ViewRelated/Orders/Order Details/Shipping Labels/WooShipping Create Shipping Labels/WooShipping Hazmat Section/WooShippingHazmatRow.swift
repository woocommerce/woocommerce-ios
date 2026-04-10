import SwiftUI

struct WooShippingHazmatRow: View {
    /// Whether the interactions (navigation/setting selection) are enabled.
    private let enabled: Bool

    @Binding private var selectedCategory: ShippingLabelHazmatCategory?

    @State private var isShowingDetailView = false

    init(selectedCategory: Binding<ShippingLabelHazmatCategory?>,
         enabled: Bool) {
        self._selectedCategory = selectedCategory
        self.enabled = enabled
    }

    var body: some View {
        VStack {
            Button(action: {
                isShowingDetailView = true
            }) {
                HStack {
                    Text(Localization.hazmatLabel)
                        .bodyStyle()
                    Spacer()
                    Text(selectedCategory != nil ? Localization.yes : Localization.no)
                        .secondaryBodyStyle()
                    Image(uiImage: .chevronImage)
                        .secondaryBodyStyle()
                        .renderedIf(enabled)
                }
            }
            .buttonStyle(.plain)
            .disabled(!enabled)

            if let category = selectedCategory {
                Text(category.localizedName)
                    .captionStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(Layout.categoryPadding)
                    .background(
                        Color(.quaternarySystemFill)
                            .clipShape(RoundedRectangle(cornerSize: .init(width: Layout.backgroundRadius,
                                                                          height: Layout.backgroundRadius)))
                    )
            }
        }
        .padding(.vertical, Layout.verticalPadding)
        .sheet(isPresented: $isShowingDetailView) {
            WooShippingHazmatDetailView(selectedCategory: selectedCategory) { selectedCategory in
                self.selectedCategory = selectedCategory
            }
        }
    }
}

private extension WooShippingHazmatRow {
    enum Layout {
        static let backgroundRadius: CGFloat = 8
        static let verticalPadding: CGFloat = 24
        static let categoryPadding: CGFloat = 16
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
    WooShippingHazmatRow(selectedCategory: .constant(nil),
                         enabled: true)
        .padding()
}
