import SwiftUI

struct POSFloatingControlView: View {
    @Environment(\.posBackgroundAppearance) var backgroundAppearance
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var showExitPOSModal: Bool
    @Binding var showSupport: Bool

    init(showExitPOSModal: Binding<Bool>, showSupport: Binding<Bool>) {
        self._showExitPOSModal = showExitPOSModal
        self._showSupport = showSupport
    }

    var body: some View {
        HStack {
            Menu {
                Button {
                    showExitPOSModal = true
                } label: {
                    Label(
                        title: { Text(Localization.exitPointOfSale) },
                        icon: { Image(systemName: "rectangle.portrait.and.arrow.forward") }
                    )
                }
                Button {
                    showSupport = true
                } label: {
                    Label(
                        title: { Text(Localization.getSupport) },
                        icon: { Image(systemName: "questionmark.circle") }
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
            .disabled(posModel.paymentState == .processingPayment)

            CardReaderConnectionStatusView()
                .foregroundStyle(fontColor)
                .background(backgroundColor)
                .cornerRadius(Constants.cornerRadius)
                .disabled(posModel.paymentState.shownFullScreen)
        }
        .frame(height: Constants.size)
        .background(Color.clear)
        .animation(.default, value: backgroundAppearance)
    }
}

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

extension POSFloatingControlView {
    static var secondaryFontColor: Color {
        return .posDarkGray.opacity(0.6)
    }
}

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
    }
}
