import Foundation

/// Provides a `ScannerContainerViewController` customized to find Product Barcode strings
///
class ProductBarcodeScannerProvider {
    static func barcodeScanner(onBarcodeScanned: @escaping (ScannedBarcode) -> Void) -> ScannerContainerViewController {
        ScannerContainerViewController(navigationTitle: Localization.title,
                                       instructionText: Localization.instructionText,
                                       onBarcodeScanned: onBarcodeScanned)
    }
}

private extension ProductBarcodeScannerProvider {
    enum Localization {
        static let title = NSLocalizedString("ProductBarcodeInputScanner.titleView",
                                             value: "Scan barcode or QR Code",
                                             comment: "Navigation bar title for scanning a barcode or QR Code to use as a product's barcode.")
        static let instructionText = NSLocalizedString("ProductBarcodeInputScanner.instructionText",
                                                       value: "Scan product barcode or QR Code",
                                                       comment: "The instruction text below the scan area in the barcode scanner for product barcode.")
    }
}
