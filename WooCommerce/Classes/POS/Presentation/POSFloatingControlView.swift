import SwiftUI

@available(iOS 17.0, *)
struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var showExitPOSModal: Bool
    @Binding private var showSupport: Bool
    @Binding private var showDocumentation: Bool

    init(showExitPOSModal: Binding<Bool>,
         showSupport: Binding<Bool>,
         showDocumentation: Binding<Bool>) {
        self._showExitPOSModal = showExitPOSModal
        self._showSupport = showSupport
        self._showDocumentation = showDocumentation
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    ServiceLocator.analytics.track(.pointOfSaleExitMenuItemTapped)
                    showExitPOSModal = true
                } label: {
                    Label(
                        title: { Text(Localization.exitPointOfSale) },
                        icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
                    )
                }
                Button {
                    ServiceLocator.analytics.track(.pointOfSaleGetSupportTapped)
                    showSupport = true
                } label: {
                    Label(
                        title: { Text(Localization.getSupport) },
                        icon: { Image(systemName: "questionmark.circle") }
                    )
                }
                Button {
                    showDocumentation = true
                } label: {
                    Label(
                        title: { Text(Localization.viewDocumentation) },
                        icon: { Image(systemName: "info.circle") }
                    )
                }
            } label: {
                VStack {
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.posBodyEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                        .foregroundStyle(fontColor)
                    Spacer()
                }
                .frame(width: Constants.size)
            }
            .background(backgroundColor)
            .cornerRadius(Constants.cornerRadius)
            .disabled(posModel.paymentState == .card(.processingPayment))

            CardReaderConnectionStatusView()
                .foregroundStyle(fontColor)
                .background(backgroundColor)
                .cornerRadius(Constants.cornerRadius)
                .disabled(posModel.paymentState.shownFullScreen)
                .disabled(horizontalSizeClass != .regular)
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
    }
}

@available(iOS 17.0, *)
private extension POSFloatingControlView {
    var backgroundColor: Color {
        switch backgroundAppearance {
        case .primary:
            colorScheme == .light ? .posSecondaryBackground : .posTertiaryBackground
        case .secondary:
            colorScheme == .light ? Color(.wooCommercePurple(.shade80)) : Color(.wooCommercePurple(.shade20))
        }
    }

    var fontColor: Color {
        switch backgroundAppearance {
        case .primary:
            .posPrimaryText
        case .secondary:
            Self.secondaryFontColor
        }
    }
}

@available(iOS 17.0, *)
extension POSFloatingControlView {
    static var secondaryFontColor: Color {
        return .posDarkGray.opacity(0.6)
    }
}

@available(iOS 17.0, *)
private extension POSFloatingControlView {
    enum Constants {
        static let size: CGFloat = 56
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let exitPointOfSale = NSLocalizedString(
            "pointOfSale.floatingButtons.exit.button.title",
            value: "Exit POS",
            comment: "The title of the floating button to exit Point of Sale, shown in a popover menu." +
            "The action is confirmed in a modal."
        )

        static let getSupport = NSLocalizedString(
            "pointOfSale.floatingButtons.getSupport.button.title",
            value: "Get Support",
            comment: "The title of the floating button to get support for Point of Sale, shown in a popover menu."
        )

        static let viewDocumentation = NSLocalizedString(
            "pointOfSale.floatingButtons.viewDocumentation.button.title",
            value: "View Documentation",
            comment: "The title of the floating button to read Point of Sale documentation, shown in a popover menu."
        )
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())

    POSFloatingControlView(showExitPOSModal: .constant(false),
                           showSupport: .constant(false),
                           showDocumentation: .constant(false))
    .environment(posModel)
}
#endif
