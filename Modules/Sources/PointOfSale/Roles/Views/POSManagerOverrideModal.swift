import SwiftUI

private struct POSManagerOverrideModalModifier: ViewModifier {
    @Environment(\.posAccessSession) private var session
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let handler: POSManagerOverrideHandler

    func body(content: Content) -> some View {
        @Bindable var handler = handler

        content
            .onAppear {
                handler.configure(session: session)
            }
            .posModal(item: $handler.request, onDismiss: {
                handler.cancel()
            }) { request in
                modalContent(for: request)
            }
    }
}

private extension POSManagerOverrideModalModifier {
    @ViewBuilder
    func modalContent(for request: POSManagerOverrideRequest) -> some View {
        if horizontalSizeClass == .compact {
            POSManagerOverrideView(handler: handler, request: request)
        } else {
            POSManagerOverrideView(handler: handler, request: request)
                .posModalSizing()
        }
    }
}

extension View {
    func posManagerOverrideModal(handler: POSManagerOverrideHandler) -> some View {
        modifier(POSManagerOverrideModalModifier(handler: handler))
    }
}

#if DEBUG
#Preview("Dashboard") {
    @Previewable @StateObject var modalManager = POSModalManager()
    @Previewable @StateObject var coverManager = POSFullScreenCoverManager()
    @Previewable @State var handler = POSManagerOverrideHandler(session: MockPOSAccessSession())

    NavigationStack {
        PointOfSaleDashboardView()
            .environment(POSPreviewHelpers.makePreviewAggregateModel())
            .posManagerOverrideModal(handler: handler)
            .posRootModal()
            .environmentObject(modalManager)
            .environmentObject(coverManager)
            .onAppear {
                handler.requestApproval(
                    for: .refundShopOrders,
                    reason: "Refunding orders requires manager approval."
                )
            }
    }
    .environment(\.posAccessSession, MockPOSAccessSession())
}

#Preview("Sample order - Invalid PIN") {
    @Previewable @StateObject var modalManager = POSModalManager()
    @Previewable @StateObject var coverManager = POSFullScreenCoverManager()
    @Previewable @State var handler = POSManagerOverrideHandler(session: MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN)))

    POSManagerOverridePreviewSurface()
        .posManagerOverrideModal(handler: handler)
        .posRootModal()
        .environmentObject(modalManager)
        .environmentObject(coverManager)
        .environment(\.posAccessSession, MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN)))
        .onAppear {
            handler.requestApproval(
                for: .publishShopCoupons,
                reason: "Creating coupons requires manager approval."
            )
            handler.pinEntryState = .error(message: "Incorrect PIN. Try again.")
        }
}

private struct POSManagerOverridePreviewSurface: View {
    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xLarge) {
            HStack {
                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text("Order #1043")
                        .font(.posHeadingBold)
                        .foregroundStyle(Color.posOnSurface)

                    Text("2 items")
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
                }

                Spacer()

                Text("$48.00")
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
            }

            VStack(spacing: POSSpacing.medium) {
                row(title: "Black hoodie", detail: "$32.00")
                row(title: "Beanie", detail: "$16.00")
            }
            .padding(POSPadding.medium)
            .background(Color.posSurfaceContainerLowest)
            .cornerRadius(POSCornerRadiusStyle.medium.value)

            Spacer()

            Button("Create coupon") {}
                .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .padding(POSPadding.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    private func row(title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)

            Spacer()

            Text(detail)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
    }
}
#endif
