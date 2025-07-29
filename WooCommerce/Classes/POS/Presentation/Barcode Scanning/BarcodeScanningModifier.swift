import SwiftUI

/// A view modifier that adds barcode scanning capability to a view.
/// The barcode scanner is added in a ZStack below the content view.
@available(iOS 17.0, *)
struct BarcodeScanningModifier: ViewModifier {
    /// Whether barcode scanning is enabled
    @Binding var enabled: Bool
    /// Callback that is triggered when a barcode is successfully scanned
    let onScan: (Result<String, HIDBarcodeParserError>) -> Void

    @Environment(\.posFeatureFlags) private var featureFlags

    private var isBarcodeScani1FeatureEnabled: Bool {
        featureFlags.isFeatureFlagEnabled(.pointOfSaleBarcodeScanningi1)
    }

    func body(content: Content) -> some View {
        ZStack {
            content

            if enabled && isBarcodeScani1FeatureEnabled {
                BarcodeScannerContainer(onScan: onScan)
            }
        }
    }
}

@available(iOS 17.0, *)
extension View {
    /// Adds barcode scanning capability to a view.
    /// - Parameters:
    ///   - enabled: A binding to control whether barcode scanning is enabled. Defaults to a constant true binding.
    ///   - onScan: Callback that is triggered when a barcode is successfully scanned.
    /// - Returns: A view with barcode scanning capability.
    func barcodeScanning(enabled: Binding<Bool> = .constant(true),
                         onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void) -> some View {
        modifier(BarcodeScanningModifier(enabled: enabled, onScan: onScan))
    }
}
