import PassKit

@MainActor
protocol WalletPresentationSuppressing {
    func suppressPresentation()
    func restorePresentation()
}

/// Prevents an external card reader from activating the merchant's Wallet during payment.
@MainActor
final class WalletPresentationSuppression: WalletPresentationSuppressing {
    private var walletSuppressionRequestToken: PKSuppressionRequestToken?

    /// Suppress wallet presentation. This requires a special entitlement from Apple:
    /// `com.apple.developer.passkit.pass-presentation-suppression`
    /// See Woo-*.entitlements in WooCommerce/Resources
    ///
    func suppressPresentation() {
        /// iPads don't support NFC passes. Attempting to call `requestAutomaticPassPresentationSuppression` on them will
        /// return 0 `notSupported`
        ///
        guard !UIDevice.isPad() else {
            return
        }

        guard !PKPassLibrary.isSuppressingAutomaticPassPresentation() else {
            return
        }

        walletSuppressionRequestToken = PKPassLibrary.requestAutomaticPassPresentationSuppression() { result in
            guard result == .success else {
                DDLogWarn("Automatic pass presentation suppression request failed. Reason: \(result.rawValue)")

                let logProperties: [String: Any] = ["PKAutomaticPassPresentationSuppressionResult": result.rawValue]
                ServiceLocator.crashLogging.logMessage(
                    "Automatic pass presentation suppression request failed",
                    properties: logProperties,
                    level: .warning
                )
                return
            }
        }
    }

    /// Restore wallet presentation.
    func restorePresentation() {
        /// iPads don't have passes (wallets) to present
        ///
        guard !UIDevice.isPad() else {
            return
        }

        guard let walletSuppressionRequestToken, walletSuppressionRequestToken != 0 else {
            return
        }

        PKPassLibrary.endAutomaticPassPresentationSuppression(withRequestToken: walletSuppressionRequestToken)
    }
}
