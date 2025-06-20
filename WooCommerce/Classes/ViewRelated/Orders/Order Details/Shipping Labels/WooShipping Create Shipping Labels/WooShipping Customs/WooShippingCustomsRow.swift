import SwiftUI
import WooFoundation
import Yosemite

struct WooShippingCustomsRow: View {
    let informationIsCompleted: Bool
    let customsFormViewModel: WooShippingCustomsFormViewModel

    @ScaledMetric private var scale: CGFloat = 1.0
    @State private var showCustomsForm: Bool = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            /// Layout option #1
            /// View fits in a given width
            HStack {
                customsRowTitleView
                Spacer()
                customsRowStatusBadgeView
                customsRowEditButtonView
            }

            /// Layout option #2 that fits in given width
            /// View doesn't fit in a given width
            HStack {
                VStack(
                    alignment: .center,
                    spacing: Layout.customsRowVerticalLayoutSpacing
                ) {
                    customsRowTitleView
                    customsRowStatusBadgeView
                }
                Spacer()
                customsRowEditButtonView
            }
        }
        .padding(Layout.borderPadding)
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.separator), lineWidth: Layout.borderWidth)
        .sheet(isPresented: $showCustomsForm) {
            WooShippingCustomsForm(viewModel: customsFormViewModel)
        }
    }
}

private extension WooShippingCustomsRow {
    var customsRowTitleView: some View {
        Text(Localization.customsTitle)
            .headlineStyle()
            .foregroundColor(.primary)
    }

    var customsRowStatusBadgeView: some View {
        Text(informationIsCompleted ? Localization.completedStatus : Localization.missingInfoStatus)
            .foregroundColor(.black)
            .captionStyle()
            .padding(.horizontal, Layout.statusBadgeHorizontalPadding)
            .padding(.vertical, Layout.statusBadgeVerticalPadding)
            .frame(minHeight: Layout.statusBadgeHeight * scale)
            .background(
                RoundedRectangle(cornerRadius: Layout.statusBadgeCornerRadius)
                    .fill(informationIsCompleted ?
                          Color.withColorStudio(name: .green, shade: .shade5) :
                            Color.withColorStudio(name: .red, shade: .shade10))
            )
    }

    var customsRowEditButtonView: some View {
        PencilEditButton {
            showCustomsForm.toggle()
        }
        .accessibilityLabel(Text(Localization.editButtonAccessibilityLabel))
    }
}

private extension WooShippingCustomsRow {
    enum Layout {
        static let borderCornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
        static let customsTitleFontSize: CGFloat = 17
        static let statusBadgeFontSize: CGFloat = 14
        static let statusBadgeCornerRadius: CGFloat = 6
        static let statusBadgeHorizontalPadding: CGFloat = 12
        static let statusBadgeVerticalPadding: CGFloat = 4
        static let customsRowVerticalLayoutSpacing: CGFloat = 6
        static let statusBadgeHeight: CGFloat = 24
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
