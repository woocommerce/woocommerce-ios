import SwiftUI

struct POSManagerOverrideView: View {
    let handler: POSManagerOverrideHandler
    let request: POSManagerOverrideRequest

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            VStack(spacing: POSSpacing.medium) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(request.reason)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }

            POSPINEntryView(state: handler.pinEntryState) { pin in
                Task {
                    await handler.submit(pin: pin)
                }
            }
            .frame(height: Constants.pinEntryHeight)

            Button(Localization.cancel) {
                handler.cancel()
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .frame(maxWidth: Constants.contentWidth)
        .padding(Constants.padding)
    }
}

private extension POSManagerOverrideView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.managerOverride.title",
            value: "Manager approval required",
            comment: "Title shown on the POS manager approval modal."
        )
        static let cancel = NSLocalizedString(
            "pos.managerOverride.cancel",
            value: "Cancel",
            comment: "Button title for dismissing the POS manager approval modal."
        )
    }

    enum Constants {
        static let contentWidth: CGFloat = 420
        static let pinEntryHeight: CGFloat = 430
        static let padding: CGFloat = POSPadding.medium
    }
}

#if DEBUG
#Preview("Manager approval") {
    let handler = POSManagerOverrideHandler(session: MockPOSAccessSession())
    let request = POSManagerOverrideRequest(
        capability: .refundShopOrders,
        reason: "Refunding orders requires manager approval."
    )
    handler.requestApproval(for: request.capability, reason: request.reason)

    return POSManagerOverrideView(handler: handler, request: request)
        .background(Color.posSurfaceBright)
}

#Preview("Invalid PIN") {
    let handler = POSManagerOverrideHandler(session: MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN)))
    let request = POSManagerOverrideRequest(
        capability: .publishShopCoupons,
        reason: "Creating coupons requires manager approval."
    )
    handler.requestApproval(for: request.capability, reason: request.reason)
    handler.pinEntryState = .error(message: "Incorrect PIN. Try again.")

    return POSManagerOverrideView(handler: handler, request: request)
        .background(Color.posSurfaceBright)
}
#endif
