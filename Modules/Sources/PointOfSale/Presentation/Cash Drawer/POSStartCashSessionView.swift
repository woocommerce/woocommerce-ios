import SwiftUI
import WooFoundation

/// Detail pane shown when "Start session" is selected in `POSCashDrawerView`.
///
/// UI-only prototype: there is no cash session interface to call yet, so the button has no working
/// action beyond analytics. Wiring to the session interface is tracked separately once the
/// Foundation team's local interface lands.
struct POSStartCashSessionView: View {
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @FocusState private var isAmountFocused: Bool
    @State private var startingCashAmount: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            POSPageHeaderView(title: Localization.title, backButtonConfiguration: nil)

            POSInformationCard {
                VStack(alignment: .leading, spacing: POSPadding.small) {
                    Text(Localization.startingCashLabel)
                        .font(.posBodyLargeBold)
                        .foregroundStyle(Color.posOnSurface)

                    HStack {
                        POSCashAmountTextField(
                            amount: $startingCashAmount,
                            isFocused: $isAmountFocused,
                            currencySettings: currencyProvider.currencySettings,
                            onSubmit: { isAmountFocused = false }
                        )
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.posSurfaceBright)
                    .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
                }
            }

            Button(Localization.startSessionButtonTitle) {
                analytics.track(.pointOfSaleCashDrawerStartSessionButtonTapped)
                // TODO: Wire to the cash session interface once the Foundation team's local
                // interface is available. No session is started yet.
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .frame(maxWidth: .infinity)
        }
        .padding(POSPadding.large)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.posSurface)
        .accessibilityIdentifier("pos-cash-drawer-start-session-view")
    }
}

private extension POSStartCashSessionView {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSaleStartCashSessionView.title",
            value: "Start a cash drawer session",
            comment: "Title of the start cash drawer session screen."
        )

        static let startingCashLabel = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startingCashLabel",
            value: "Starting cash",
            comment: "Label for the starting cash amount field when starting a cash drawer session."
        )

        static let startSessionButtonTitle = NSLocalizedString(
            "pointOfSaleStartCashSessionView.startSessionButtonTitle",
            value: "Start session",
            comment: "Title of the button that starts a new cash drawer session."
        )
    }
}

#if DEBUG
#Preview {
    POSStartCashSessionView()
}
#endif
