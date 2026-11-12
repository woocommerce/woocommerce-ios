import SwiftUI

/// The only content a POS dialog can have. Present it with `posDialog`, which draws the card, the corner X and the width.
struct POSDialog {
    typealias Action = PointOfSaleFlowButtonConfiguration.ButtonConfig

    struct CloseAction {
        let accessibilityLabel: String
        let accessibilityIdentifier: String?
        let action: () -> Void

        init(accessibilityLabel: String, accessibilityIdentifier: String? = nil, action: @escaping () -> Void) {
            self.accessibilityLabel = accessibilityLabel
            self.accessibilityIdentifier = accessibilityIdentifier
            self.action = action
        }
    }

    enum Icon {
        case exclamationMark
        case errorXMark
    }

    let icon: Icon?
    let title: String
    let message: String
    let primaryAction: Action
    let secondaryAction: Action?
    let closeAction: CloseAction?

    init(icon: Icon? = nil,
         title: String,
         message: String,
         primaryAction: Action,
         secondaryAction: Action? = nil,
         closeAction: CloseAction? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.closeAction = closeAction
    }
}

extension View {
    func posDialog(isPresented: Binding<Bool>,
                   onDismiss: (() -> Void)? = nil,
                   dialog: @escaping () -> POSDialog) -> some View {
        posModal(isPresented: isPresented, compactStyle: .dialog, onDismiss: onDismiss) {
            POSDialogView(dialog: dialog())
        }
    }

    func posDialog<Item: Identifiable & Equatable>(item: Binding<Item?>,
                                                   onDismiss: (() -> Void)? = nil,
                                                   dialog: @escaping (Item) -> POSDialog) -> some View {
        posModal(item: item, compactStyle: .dialog, onDismiss: onDismiss) { item in
            POSDialogView(dialog: dialog(item))
        }
    }
}

struct POSDialogView: View {
    @Environment(\.posMetrics) private var metrics
    let dialog: POSDialog

    var body: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            if let closeAction = dialog.closeAction {
                POSModalCloseButton(accessibilityLabel: closeAction.accessibilityLabel,
                                    accessibilityIdentifier: closeAction.accessibilityIdentifier,
                                    fontStyle: .posButtonSymbolLarge,
                                    closeAction: closeAction.action)
                .padding([.top, .trailing], metrics.padding.small)
            }

            switch dialog.icon {
            case .exclamationMark:
                POSErrorExclamationMark(size: .large)
            case .errorXMark:
                POSErrorXMark(size: .large)
            case nil:
                EmptyView()
            }

            VStack(spacing: metrics.spacing.xLarge) {
                Text(dialog.title)
                    .font(.posHeadingBold)
                    .accessibilityAddTraits(.isHeader)
                Text(dialog.message)
                    .font(.posBodyLargeRegular())
            }
            .foregroundStyle(Color.posOnSurface)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            POSFlowButtonsView(configuration: .init(primaryButton: dialog.primaryAction, secondaryButton: dialog.secondaryAction))
        }
        .padding(metrics.padding.medium)
        .frame(maxWidth: metrics.dialogMaxWidth)
    }
}

extension POSMetrics {
    var dialogMaxWidth: CGFloat {
        900
    }
}

#if DEBUG
#Preview("Compact") {
    POSDialogView(dialog: .init(title: "Exit Point of Sale mode?",
                                message: "Any orders in progress will be lost.",
                                primaryAction: .init(title: "Exit", action: {}),
                                closeAction: .init(accessibilityLabel: "Close", action: {})))
    .environment(\.horizontalSizeClass, .compact)
}

#Preview("With icon") {
    POSDialogView(dialog: .init(icon: .exclamationMark,
                                title: "Receipt didn't print",
                                message: "The printer is out of paper.",
                                primaryAction: .init(title: "Retry", action: {}),
                                secondaryAction: .init(title: "Email receipt", action: {}),
                                closeAction: .init(accessibilityLabel: "Close", action: {})))
}

#Preview("Regular") {
    POSDialogView(dialog: .init(title: "Exit Point of Sale mode?",
                                message: "Any orders in progress will be lost.",
                                primaryAction: .init(title: "Exit", action: {}),
                                secondaryAction: .init(title: "Cancel", action: {}),
                                closeAction: .init(accessibilityLabel: "Close", action: {})))
    .environment(\.horizontalSizeClass, .regular)
}
#endif
