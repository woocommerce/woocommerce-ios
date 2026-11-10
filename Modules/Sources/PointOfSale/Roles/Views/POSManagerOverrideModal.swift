import SwiftUI

/// A view-facing request to perform a capability-gated action. Called with the action to run, it either
/// runs it immediately (the operator holds the capability) or presents the manager-override modal and runs
/// it once an authorized staff member approves. Views default it to running the action directly, which keeps
/// previews and ungated hosts working without a real gate.
typealias POSPermissionRequest = (_ perform: @escaping () -> Void) -> Void

private struct POSManagerOverrideModalModifier: ViewModifier {
    @Environment(\.posAccessSession) private var session

    let handler: POSManagerOverrideHandler

    func body(content: Content) -> some View {
        content
            .onAppear {
                handler.configure(session: session)
            }
            .posModal(item: requestBinding, compactStyle: .managerApproval) { request in
                modalContent(for: request)
            }
    }

    private var requestBinding: Binding<POSManagerOverrideRequest?> {
        Binding(
            get: { handler.request },
            set: { newValue in
                if newValue == nil {
                    handler.cancel()
                }
            }
        )
    }
}

private extension POSManagerOverrideModalModifier {
    @ViewBuilder
    func modalContent(for request: POSManagerOverrideRequest) -> some View {
        POSManagerOverrideView(handler: handler, request: request)
            .posManagerOverrideModalSizing()
    }
}

extension POSModalCompactStyle {
    /// The PIN pad needs most of the phone screen, so on phone manager approval takes the whole screen.
    static var managerApproval: POSModalCompactStyle {
        .fullScreen(title: NSLocalizedString(
            "pos.managerOverride.modal.title",
            value: "Manager approval",
            comment: "Title in the header of the full-screen manager approval PIN screen on phone."
        ))
    }
}

extension View {
    func posManagerOverrideModal(handler: POSManagerOverrideHandler) -> some View {
        modifier(POSManagerOverrideModalModifier(handler: handler))
    }
}

private extension View {
    func posManagerOverrideModalSizing() -> some View {
        modifier(POSManagerOverrideModalSizing())
    }
}

private struct POSManagerOverrideModalSizing: ViewModifier {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posModalParentSize) private var parentSize

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(width: frameWidth)
    }
}

private extension POSManagerOverrideModalSizing {
    var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var horizontalPadding: CGFloat {
        isCompactWidth ? metrics.padding.none : metrics.padding.xxLarge
    }

    var verticalPadding: CGFloat {
        isCompactWidth ? metrics.padding.none : metrics.padding.xxLarge
    }

    var frameWidth: CGFloat? {
        guard !isCompactWidth else {
            return nil
        }
        return min(parentSize.width, POSPINEntryView.contentWidth + metrics.padding.xxLarge * 2)
    }
}

#if DEBUG
#Preview("Sample order") {
    POSManagerOverridePreview(
        session: MockPOSAccessSession(),
        capability: .issueRefunds,
        reason: "Issue a refund for Order #1043"
    )
}

#Preview("Sample order - Invalid PIN") {
    POSManagerOverridePreview(
        session: MockPOSAccessSession(managerApprovalResult: .failure(.invalidPIN)),
        capability: .createCoupons,
        reason: "Creating coupons requires manager approval",
        pinEntryState: .error(kind: .invalidPIN)
    )
}

private struct POSManagerOverridePreview: View {
    @StateObject private var modalManager = POSModalManager()
    @StateObject private var coverManager = POSFullScreenCoverManager()
    @State private var handler: POSManagerOverrideHandler

    private let session: MockPOSAccessSession
    private let capability: POSCapability
    private let reason: String

    init(session: MockPOSAccessSession,
         capability: POSCapability,
         reason: String,
         pinEntryState: POSPINEntryState = .idle) {
        self.session = session
        self.capability = capability
        self.reason = reason
        self._handler = State(initialValue: POSManagerOverrideHandler(
            session: session,
            initialRequest: POSManagerOverrideRequest(capability: capability, reason: reason),
            initialPINEntryState: pinEntryState
        ))
    }

    var body: some View {
        POSManagerOverridePreviewSurface()
            .posManagerOverrideModal(handler: handler)
            .posRootModal()
            .environmentObject(modalManager)
            .environmentObject(coverManager)
            .environment(\.posAccessSession, session)
    }
}

private struct POSManagerOverridePreviewSurface: View {
    var body: some View {
        VStack(alignment: .leading, spacing: POSMetrics.regular.spacing.xLarge) {
            HStack {
                VStack(alignment: .leading, spacing: POSMetrics.regular.spacing.xSmall) {
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

            VStack(spacing: POSMetrics.regular.spacing.medium) {
                row(title: "Black hoodie", detail: "$32.00")
                row(title: "Beanie", detail: "$16.00")
            }
            .padding(POSMetrics.regular.padding.medium)
            .background(Color.posSurfaceContainerLowest)
            .cornerRadius(POSCornerRadiusStyle.medium.value)

            Spacer()

            Button("Create coupon") {}
                .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .padding(POSMetrics.regular.padding.xxLarge)
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
