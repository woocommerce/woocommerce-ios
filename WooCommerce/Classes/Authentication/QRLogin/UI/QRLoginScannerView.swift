import SwiftUI
import Vision

/// SwiftUI wrapper around `CodeScannerViewController`. Wraps it in a
/// `UIViewControllerRepresentable` so we can compose it with the QR-login
/// chrome (URL pill, close button) in SwiftUI.
///
/// `onScannedPayload` fires once per QR result; the coordinator is
/// responsible for stopping further scans (e.g. by dismissing this view)
/// once it accepts a payload.
struct QRLoginScannerView: View {
    let onScannedPayload: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            QRLoginScannerRepresentable(onScannedPayload: onScannedPayload)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .padding(Constants.standardPadding)
                            .background(
                                Circle().fill(Color.black.opacity(Constants.cancelButtonBackgroundOpacity))
                            )
                            .foregroundColor(.white)
                            .accessibilityLabel(Localization.cancelAccessibility)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, Constants.smallPadding)

                Spacer()

                Text(Localization.urlPill)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, Constants.urlPillHorizontalPadding)
                    .padding(.vertical, Constants.urlPillVerticalPadding)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.urlPillCornerRadius)
                            .fill(Color.black.opacity(Constants.urlPillBackgroundOpacity))
                    )
                    .padding(.bottom, Constants.largePadding)
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
            // The QR-login scanner draws its own close control over the camera
            // feed, so the controller's built-in cancel button is hidden.
            format: .barcode(completion: { result in
                guard case let .success(barcodes) = result else { return }
                guard let payload = barcodes
                    .first(where: { $0.symbology == .qr })?
                    .payloadStringValue else { return }
                Task { @MainActor in
                    context.coordinator.deliver(payload: payload)
                }
            }),
            showsBuiltInCancelButton: false
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

private extension QRLoginScannerView {
    enum Constants {
        static let smallPadding: CGFloat = 8
        static let standardPadding: CGFloat = 12
        static let largePadding: CGFloat = 32
        static let cancelButtonBackgroundOpacity = 0.4
        static let urlPillHorizontalPadding: CGFloat = 18
        static let urlPillVerticalPadding: CGFloat = 10
        static let urlPillCornerRadius: CGFloat = 18
        static let urlPillBackgroundOpacity = 0.5
    }
}

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
    }
}
