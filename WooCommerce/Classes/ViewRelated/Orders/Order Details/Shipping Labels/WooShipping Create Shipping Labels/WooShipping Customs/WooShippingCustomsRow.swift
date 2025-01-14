import SwiftUI
import WooFoundation
import Yosemite

struct WooShippingCustomsRow: View {
    let informationIsCompleted: Bool
    let customsFormViewModel: WooShippingCustomsFormViewModel

    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var showCustomsForm: Bool = false

    var body: some View {
        AdaptiveStack {
            Text(Localization.customsTitle)
                .headlineStyle()
                .foregroundColor(.primary)

            Spacer()

            Text(informationIsCompleted ? Localization.completedStatus : Localization.missingInfoStatus)
                .captionStyle()
                .foregroundColor(.black)
                .padding(.horizontal, Layout.statusBadgeHorizontalPadding)
                .padding(.vertical, Layout.statusBadgeVerticalPadding)
                .background(
                    RoundedRectangle(cornerRadius: Layout.statusBadgeCornerRadius)
                        .fill(informationIsCompleted ?
                              Color.withColorStudio(name: .green, shade: .shade5) :
                                Color.withColorStudio(name: .red, shade: .shade10))
                )
                .padding(.horizontal, 10)

            PencilEditButton {
                showCustomsForm.toggle()
            }
            .accessibilityLabel(Text(Localization.editButtonAccessibilityLabel))
        }
        .padding(Layout.borderPadding)
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderWidth)
        .sheet(isPresented: $showCustomsForm) {
            WooShippingCustomsForm(viewModel: customsFormViewModel)
        }
    }
}

private extension WooShippingCustomsRow {
    enum Layout {
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
        static let pencilButtonSizeDimensions: CGFloat = 22
        static let customsTitleFontSize: CGFloat = 17
        static let statusBadgeFontSize: CGFloat = 14
        static let statusBadgeCornerRadius: CGFloat = 6
        static let statusBadgeHorizontalPadding: CGFloat = 12
        static let statusBadgeVerticalPadding: CGFloat = 6
        static let borderPadding: CGFloat = 16
    }
}

private extension WooShippingCustomsRow {
    enum Localization {
        static let customsTitle = NSLocalizedString("shippingLabels.customs.customsTitle",
                                                    value: "Customs",
                                                    comment: "Customs row title in the main Shipping Labels view")
        static let completedStatus = NSLocalizedString("shippingLabels.customs.completedBadge",
                                                       value: "Completed",
                                                       comment: "Badge wording when the customs information is completed")
        static let missingInfoStatus = NSLocalizedString("shippingLabels.customs.missingInfo",
                                                         value: "Missing info",
                                                         comment: "Badge wording when the customs information is missing")
        static let editButtonAccessibilityLabel = NSLocalizedString("shippingLabels.customs.editButtonAccessibiliy",
                                                                      value: "Edit Shipping Labels Customs Info",
                                                                      comment: "Accessibility label for the button to edit the shipping labels customs")
    }
}
