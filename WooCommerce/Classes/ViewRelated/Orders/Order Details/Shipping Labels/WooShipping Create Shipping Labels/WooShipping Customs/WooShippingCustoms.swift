import SwiftUI
import WooFoundation

struct WooShippingCustoms: View {
    let informationIsCompleted: Bool
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        HStack {
            // Title
            Text(Localization.customsTitle)
                .font(.system(size: Layout.customsTitleFontSize, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            Text(informationIsCompleted ? Localization.completedStatus : Localization.missingInfoStatus)
                .font(.system(size: Layout.statusBadgeFontSize, weight: .medium))
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

            Button {
            } label: {
                Image(systemName: "pencil")
                    .resizable()
                    .frame(width: Layout.pencilButtonSizeDimensions * scale,
                           height: Layout.pencilButtonSizeDimensions * scale)
            }
            .tint(Color(.primary))
        }
        .padding(Layout.borderPadding)
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderWidth)
    }
}

private extension WooShippingCustoms {
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

private extension WooShippingCustoms {
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
    }
}
