import SwiftUI

/// A SwiftUI view that provides barcode scanning functionality by capturing keyboard input.
/// This container is designed to be invisible and non-interactive, serving as a bridge between
/// physical barcode scanners and the app's scanning functionality.
///
/// The container works by capturing keyboard input events and interpreting them as barcode scans
/// when a terminating character is detected.
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

/// A UIHostingController that dynamically switches between GameController and UIKit barcode scanning
/// based on VoiceOver state. Uses GameController framework for optimal performance when possible,
/// and falls back to UIKit UIPress events when VoiceOver is enabled.
final class GameControllerBarcodeScannerHostingController: UIHostingController<EmptyView> {
    /// periphery: ignore - retain `gameControllerObserver` to keep it alive
    private(set) var gameControllerObserver: GameControllerBarcodeObserver?

    private(set) var uiKitObserver: UIKitBarcodeObserver?

    private let configuration: HIDBarcodeParserConfiguration
    private let onScan: (Result<String, HIDBarcodeParserError>) -> Void
    private let voiceOverStateProvider: VoiceOverStateProvider
    private let analytics: POSAnalyticsProviding

    // Public initializer for production use
    init(
        configuration: HIDBarcodeParserConfiguration,
        analytics: POSAnalyticsProviding,
        onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void,
        voiceOverStateProvider: VoiceOverStateProvider = SystemVoiceOverStateProvider()
    ) {
        self.configuration = configuration
        self.onScan = onScan
        self.voiceOverStateProvider = voiceOverStateProvider
        self.analytics = analytics
        super.init(rootView: EmptyView())

        setupInitialObserver()
        observeVoiceOverChanges()
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanupObservers()
    }

    // MARK: - Observer Management

    private func setupInitialObserver() {
        switchToAppropriateObserver()
    }

    private func observeVoiceOverChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }

    @objc private func voiceOverStatusChanged() {
        switchToAppropriateObserver()
    }

    private func switchToAppropriateObserver() {
        // Clean up current observers
        cleanupObservers()

        // Set up appropriate observer based on VoiceOver state
        if voiceOverStateProvider.isVoiceOverRunning {
            uiKitObserver = UIKitBarcodeObserver(
                configuration: configuration,
                analytics: analytics,
                onScan: onScan
            )
        } else {
            gameControllerObserver = GameControllerBarcodeObserver(
                configuration: configuration,
                analytics: analytics,
                onScan: onScan
            )
        }
    }

    private func cleanupObservers() {
        gameControllerObserver = nil
        uiKitObserver = nil
    }

    // MARK: - UIPress Event Handling

    override var canBecomeFirstResponder: Bool {
        voiceOverStateProvider.isVoiceOverRunning
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if voiceOverStateProvider.isVoiceOverRunning {
            becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if voiceOverStateProvider.isVoiceOverRunning {
            resignFirstResponder()
        }
    }

    /// Handles the end of keyboard press events, interpreting them as barcode input.
    /// When a terminating character is detected, the accumulated buffer is treated as a complete
    /// barcode and passed to the onScan callback.
    /// We don't call `super` when UIKitObserver is active because we don't other responder chain items to handle our barcode as well,
    /// as this could cause unexpected behavior.
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        // Forward UIPress events to UIKit observer if active
        if let uiKitObserver {
            uiKitObserver.processUIPress(presses)
        } else {
            super.pressesEnded(presses, with: event)
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        // Don't call super to prevent system from hiding software keyboard
    }

    override func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesChanged(presses, with: event)
    }

    /// `pressesCancelled` is rarely called, but Apple's documentation suggests it's possible and that crashes may occur if it's not handled.
    /// It makes sense to clear the buffer when this happens.
    /// We call super in case other presses are handled elsewhere in the responder chain.
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let uiKitObserver {
            uiKitObserver.barcodeParser?.cancel()
        }
        super.pressesCancelled(presses, with: event)
    }
}
