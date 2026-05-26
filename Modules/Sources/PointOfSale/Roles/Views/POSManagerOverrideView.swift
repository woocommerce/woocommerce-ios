import SwiftUI

struct POSManagerOverrideView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let handler: POSManagerOverrideHandler
    let request: POSManagerOverrideRequest

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            header

            POSPINEntryView(state: handler.pinEntryState) { pin in
                Task {
                    await handler.submit(pin: pin)
                }
            }
            .layoutPriority(1)

            Button(Localization.cancel) {
                handler.cancel()
            }
            .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, isCompactWidth ? POSPadding.medium : POSPadding.none)
        .padding(.top, isCompactWidth ? POSPadding.large : POSPadding.none)
        .padding(.bottom, isCompactWidth ? POSPadding.xxLarge : POSPadding.none)
    }
}

private extension POSManagerOverrideView {
    var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var header: some View {
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
    }

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
}
