import SwiftUI
import WooFoundation
import struct WooFoundationCore.WooAnalyticsEvent

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
struct POSListErrorView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    @Environment(\.posAnalytics) private var analytics

    private let error: PointOfSaleErrorState
    @State private var buttonWidth: CGFloat? = nil
    private let viewModel: POSErrorViewModel

    @Environment(\.keyboardObserver) private var keyboard

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil, onExit: (() -> Void)? = nil) {
        self.error = error
        let actionButton: POSErrorButtonViewModel? = {
            guard let onAction else { return nil }
            return POSErrorButtonViewModel(title: error.buttonText,
                                           buttonStyle: (POSFilledButtonStyle(size: .normal)),
                                           action: onAction)
        }()
        let exitButton: POSErrorButtonViewModel? = {
            guard let onExit else { return nil }
            return POSErrorButtonViewModel(title: Localization.exitButtonText,
                                           buttonStyle: POSOutlinedButtonStyle(size: .normal),
                                           action: onExit)
        }()

        self.viewModel = POSErrorViewModel(error: error, primaryButton: actionButton, secondaryButton: exitButton)
    }

    var body: some View {
        ScrollableVStack {
            Spacer()
            POSErrorView(viewModel: viewModel, buttonWidth: $buttonWidth)
            Spacer()
        }
        .padding(.bottom, !keyboard.isFullSizeKeyboardVisible ? floatingControlAreaSize.height : 0)
        .measureWidth { width in
            buttonWidth = width / 2
        }
        .onAppear {
            // Track error shown for splash screen errors (initial catalog sync)
            if error.errorType == .initialCatalogSyncError {
                analytics.track(event: WooAnalyticsEvent.LocalCatalog.splashScreenErrorShown())
            }
        }
    }
}

private enum Localization {
    static let exitButtonText = NSLocalizedString(
        "pos.listError.exitButton",
        value: "Exit POS",
        comment: "Button text to exit Point of Sale when there's a critical error"
    )
}

#Preview {
    POSListErrorView(error: .errorCouponsDisabled, onAction: {})
}

#Preview {
    POSListErrorView(error: .errorOnLoadingCoupons(), onAction: {})
}
