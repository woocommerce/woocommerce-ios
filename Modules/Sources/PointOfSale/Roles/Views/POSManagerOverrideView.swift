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
    let overrideState: POSManagerOverrideState
    let onPINEntered: (String) -> Void
    let onCancelled: () -> Void

    @State private var pinState: POSPINEntryState = .idle
    @State private var isApproved: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            closeButtonRow
            contentSection
        }
        .padding(POSPadding.xLarge)
        .frame(maxWidth: Constants.modalMaxWidth)
        .background(Color.posSurfaceBright)
        .cornerRadius(POSCornerRadiusStyle.large.value)
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

    private var contentSection: some View {
        VStack(spacing: POSSpacing.xLarge) {
            iconSection
            POSPINEntryView(
                title: Localization.title,
                subtitle: actionDescription,
                state: $pinState,
                onPINEntered: { pin in
                    pinState = .loading
                    onPINEntered(pin)
                }
            )
        }
    }

    private var iconSection: some View {
        Image(systemName: isApproved ? "checkmark.circle.fill" : "lock.shield")
            .font(.system(size: Constants.iconSize, weight: .regular))
            .foregroundColor(isApproved ? .posSuccess : .posOnSurfaceVariantLowest)
            .contentTransition(.symbolEffect(.replace))
            .accessibilityLabel(isApproved ? Localization.approved : Localization.title)
    }

    // MARK: - State Handling

    private func handleOverrideStateChange(_ newState: POSManagerOverrideState) {
        switch newState {
        case .awaitingPIN:
            pinState = .idle
            isApproved = false
        case .error(let message):
            pinState = .error(message: message)
            isApproved = false
        case .approved:
            pinState = .loading
            withAnimation {
                isApproved = true
            }
        }
    }
}

// MARK: - Constants

private extension POSManagerOverrideView {
    enum Constants {
        static let iconSize: CGFloat = 48
        static let modalMaxWidth: CGFloat = 500
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
    POSManagerOverrideView(
        actionDescription: "Process a refund for Order #1042",
        overrideState: .awaitingPIN,
        onPINEntered: { _ in },
        onCancelled: {}
    )
    .padding()
    .background(Color.posSurfaceDim)
}

#Preview("Manager Override - Approved") {
    POSManagerOverrideView(
        actionDescription: "Process a refund for Order #1042",
        overrideState: .approved,
        onPINEntered: { _ in },
        onCancelled: {}
    )
    .padding()
    .background(Color.posSurfaceDim)
}
#endif
