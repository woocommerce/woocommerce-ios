import SwiftUI

/// A SwiftUI view that provides barcode scanning functionality by capturing keyboard input.
/// This container is designed to be invisible and non-interactive, serving as a bridge between
/// physical barcode scanners and the app's scanning functionality.
///
/// The container works by capturing keyboard input events and interpreting them as barcode scans
/// when a terminating character is detected.
@available(iOS 17.0, *)
struct BarcodeScannerContainer: View {
    /// Configuration for the barcode scanner
    let configuration: HIDBarcodeParserConfiguration
    /// Callback that is triggered when a barcode scan completes (success or failure)
    let onScan: (Result<String, HIDBarcodeParserError>) -> Void

    @Environment(\.posAnalytics) private var analytics

    init(
        configuration: HIDBarcodeParserConfiguration = .default,
        onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void
    ) {
        self.configuration = configuration
        self.onScan = onScan
    }

    var body: some View {
        BarcodeScannerContainerRepresentable(
            configuration: configuration,
            analytics: analytics,
            onScan: onScan
        )
        .frame(width: 0, height: 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A UIViewControllerRepresentable that bridges SwiftUI with UIKit to handle keyboard input events.
/// This component is responsible for creating and managing the UIKit view controller that captures
/// keyboard input for barcode scanning.
struct BarcodeScannerContainerRepresentable: UIViewControllerRepresentable {
    let configuration: HIDBarcodeParserConfiguration
    let analytics: POSAnalyticsProviding
    let onScan: (Result<String, HIDBarcodeParserError>) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        return GameControllerBarcodeScannerHostingController(
            configuration: configuration,
            analytics: analytics,
            onScan: onScan
        )
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

/// A UIHostingController that handles GameController keyboard input events for barcode scanning.
/// This controller uses GameController framework exclusively for language-independent barcode scanning.
final class GameControllerBarcodeScannerHostingController: UIHostingController<EmptyView> {
    private var gameControllerBarcodeObserver: GameControllerBarcodeObserver?

    init(
        configuration: HIDBarcodeParserConfiguration,
        analytics: POSAnalyticsProviding,
        onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void
    ) {
        super.init(rootView: EmptyView())

        gameControllerBarcodeObserver = GameControllerBarcodeObserver(
            configuration: configuration,
            analytics: analytics,
            onScan: onScan
        )
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        gameControllerBarcodeObserver = nil
    }
}
