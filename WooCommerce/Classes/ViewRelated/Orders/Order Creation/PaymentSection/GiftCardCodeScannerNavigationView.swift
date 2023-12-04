import SwiftUI

/// SwiftUI view from UIKit view controller `GiftCardCodeScannerViewController`.
struct GiftCardCodeScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = GiftCardCodeScannerViewController

    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> GiftCardCodeScannerViewController {
        GiftCardCodeScannerViewController(onCodeScanned: { code in
            onCodeScanned(code)
        })
    }

    func updateUIViewController(_ uiViewController: GiftCardCodeScannerViewController, context: Context) {
        // no-op
    }
}

/// `GiftCardCodeScannerViewController` in a navigation controller.
struct GiftCardCodeScannerNavigationView: View {
    let onCodeScanned: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationView {
            GiftCardCodeScannerView(onCodeScanned: { code in
                onCodeScanned(code)
            })
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.close, action: {
                        onClose()
                    })
                }
            }
        }
    }
}

struct GiftCardCodeScannerNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        GiftCardCodeScannerNavigationView(onCodeScanned: { _ in }, onClose: {})
    }
}

private extension GiftCardCodeScannerNavigationView {
    enum Localization {
        static let title = NSLocalizedString("Scan gift card", comment: "Navigation bar title of the gift card code scanner.")
        static let close = NSLocalizedString("Close", comment: "Navigation bar action to close the gift card code scanner.")
    }
}
