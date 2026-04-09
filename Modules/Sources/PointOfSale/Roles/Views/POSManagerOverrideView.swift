import SwiftUI

/// State driving the manager override flow.
enum POSManagerOverrideState: Equatable {
    /// Awaiting manager PIN input.
    case awaitingPIN
    /// PIN was accepted, showing a brief success indicator before auto-dismiss.
    case approved
    /// PIN was rejected, showing an error in the PIN entry.
    case error(message: String)
}

/// Modal overlay for manager approval of restricted actions.
/// Embeds a PIN entry numpad; the parent drives verification and state transitions.
struct POSManagerOverrideView: View {
    let actionDescription: String
    let capability: String
    let onPINEntered: (String) -> Void
    let onCancelled: () -> Void

    @Binding var overrideState: POSManagerOverrideState

    @State private var pinState: POSPINEntryState = .idle

    init(actionDescription: String,
         capability: String,
         overrideState: Binding<POSManagerOverrideState>,
         onPINEntered: @escaping (String) -> Void,
         onCancelled: @escaping () -> Void) {
        self.actionDescription = actionDescription
        self.capability = capability
        self._overrideState = overrideState
        self.onPINEntered = onPINEntered
        self.onCancelled = onCancelled
    }

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            closeButtonRow
            contentSection
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .frame(width: Constants.modalWidth)
        .onChange(of: overrideState) { _, newState in
            handleOverrideStateChange(newState)
        }
    }

    // MARK: - Close Button

    private var closeButtonRow: some View {
        HStack {
            Spacer()
            Button {
                onCancelled()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .foregroundColor(.posOnSurfaceVariantLowest)
            .accessibilityLabel(Localization.closeAccessibilityLabel)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentSection: some View {
        switch overrideState {
        case .awaitingPIN, .error:
            pinInputContent
        case .approved:
            approvedContent
        }
    }

    private var pinInputContent: some View {
        VStack(spacing: POSSpacing.xLarge) {
            iconSection
            POSPINEntryView(
                title: Localization.title,
                subtitle: actionDescription,
                state: $pinState,
                onPINEntered: { pin in
                    onPINEntered(pin)
                },
                onCancel: {
                    onCancelled()
                }
            )
        }
    }

    private var iconSection: some View {
        Image(systemName: "lock.shield")
            .font(.system(size: Constants.iconSize, weight: .regular))
            .foregroundColor(.posOnSurfaceVariantLowest)
    }

    private var approvedContent: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: Constants.successIconSize, weight: .regular))
                .foregroundColor(.posSuccess)
            Text(Localization.approved)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, POSPadding.xxLarge)
        .transition(.opacity)
    }

    // MARK: - State Handling

    private func handleOverrideStateChange(_ newState: POSManagerOverrideState) {
        switch newState {
        case .awaitingPIN:
            pinState = .idle
        case .error(let message):
            pinState = .error(message: message)
        case .approved:
            break
        }
    }
}

// MARK: - Constants

private extension POSManagerOverrideView {
    enum Constants {
        static let modalWidth: CGFloat = 500
        static let iconSize: CGFloat = 48
        static let successIconSize: CGFloat = 64
    }
}

// MARK: - Localization

private extension POSManagerOverrideView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.managerOverride.title",
            value: "Manager approval required",
            comment: "Title of the manager override modal in POS"
        )
        static let approved = NSLocalizedString(
            "pos.managerOverride.approved",
            value: "Approved",
            comment: "Success message shown after a manager override is approved in POS"
        )
        static let closeAccessibilityLabel = NSLocalizedString(
            "pos.managerOverride.close.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for the close button on the POS manager override modal"
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Manager Override - PIN Entry") {
    @Previewable @State var state: POSManagerOverrideState = .awaitingPIN

    POSManagerOverrideView(
        actionDescription: "Process a refund for Order #1042",
        capability: "woocommerce_refund_orders",
        overrideState: $state,
        onPINEntered: { _ in
            state = .error(message: "Invalid PIN")
        },
        onCancelled: {}
    )
    .padding()
    .background(Color.posSurfaceDim)
}

#Preview("Manager Override - Approved") {
    @Previewable @State var state: POSManagerOverrideState = .approved

    POSManagerOverrideView(
        actionDescription: "Process a refund for Order #1042",
        capability: "woocommerce_refund_orders",
        overrideState: $state,
        onPINEntered: { _ in },
        onCancelled: {}
    )
    .padding()
    .background(Color.posSurfaceDim)
}
#endif
