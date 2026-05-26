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
#Preview("Modifier over dashboard") {
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

#Preview("Modifier over dashboard - Phone") {
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
    .environment(\.horizontalSizeClass, .compact)
    .environment(\.posAccessSession, MockPOSAccessSession())
    .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
}
#endif
