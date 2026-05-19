import SwiftUI
import Vision

/// SwiftUI wrapper around `CodeScannerViewController`. Wraps it in a
/// `UIViewControllerRepresentable` so we can compose it with the QR-login
/// chrome (URL pill, help button) in SwiftUI.
///
/// `onScannedPayload` fires once per QR result; the coordinator is
/// responsible for stopping further scans (e.g. by dismissing this view)
/// once it accepts a payload.
struct QRLoginScannerView: View {
    let onScannedPayload: (String) -> Void
    let onCancel: () -> Void
    let onHelpTapped: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            QRLoginScannerRepresentable(onScannedPayload: onScannedPayload)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .padding(12)
                            .background(
                                Circle().fill(Color.black.opacity(0.4))
                            )
                            .foregroundColor(.white)
                            .accessibilityLabel(Localization.cancelAccessibility)
                    }
                    Spacer()
                    Button(action: onHelpTapped) {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                            .padding(12)
                            .background(
                                Circle().fill(Color.black.opacity(0.4))
                            )
                            .foregroundColor(.white)
                            .accessibilityLabel(Localization.helpAccessibility)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                Text(Localization.urlPill)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.5))
                    )
                    .padding(.bottom, 32)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

private struct QRLoginScannerRepresentable: UIViewControllerRepresentable {
    let onScannedPayload: (String) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let scanner = CodeScannerViewController(
            instructionText: QRLoginScannerView.Localization.instruction,
            format: .barcode(completion: { result in
                guard case let .success(barcodes) = result else { return }
                guard let payload = barcodes
                    .first(where: { $0.symbology == .qr })?
                    .payloadStringValue else { return }
                Task { @MainActor in
                    context.coordinator.deliver(payload: payload)
                }
            })
        )
        return scanner
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScannedPayload: onScannedPayload)
    }

    @MainActor
    final class Coordinator {
        private let onScannedPayload: (String) -> Void
        private var delivered = false

        init(onScannedPayload: @escaping (String) -> Void) {
            self.onScannedPayload = onScannedPayload
        }

        func deliver(payload: String) {
            guard delivered == false else { return }
            delivered = true
            onScannedPayload(payload)
        }
    }
}

// MARK: - Localization

extension QRLoginScannerView {
    enum Localization {
        static let urlPill = NSLocalizedString(
            "qrLogin.scanner.urlPill",
            value: "Visit woo.com/mobilelogin",
            comment: "URL pill shown above the scanner viewfinder."
        )
        static let instruction = NSLocalizedString(
            "qrLogin.scanner.instruction",
            value: "Center the QR code in the frame",
            comment: "Instruction text shown below the scanner viewfinder."
        )
        static let cancelAccessibility = NSLocalizedString(
            "qrLogin.scanner.cancel.accessibility",
            value: "Cancel",
            comment: "Accessibility label for the cancel button on the QR scanner."
        )
        static let helpAccessibility = NSLocalizedString(
            "qrLogin.scanner.help.accessibility",
            value: "Help",
            comment: "Accessibility label for the help button on the QR scanner."
        )
    }
}
