import Foundation

/// Provides a `ScannerContainerViewController` customized to find Product SKU strings
///
class SKUCodeScannerProvider {
    static func SKUCodeScanner(onBarcodeScanned: @escaping (ScannedBarcode) -> Void) -> ScannerContainerViewController {
        ScannerContainerViewController(navigationTitle: Localization.title,
                                       instructionText: Localization.instructionText,
                                       onBarcodeScanned: onBarcodeScanned)
    }
}

private extension SKUCodeScannerProvider {
    enum Localization {
        static let title = NSLocalizedString("ProductSKUInputScanner.titleView",
                                             value: "Scan barcode or QR Code to update SKU",
                                             comment: "Navigation bar title for scanning a barcode or QR Code to use as a product's SKU.")
        static let instructionText = NSLocalizedString("ProductSKUInputScanner.instructionText",
                                                       value: "Scan product barcode or QR Code",
                                                       comment: "The instruction text below the scan area in the barcode scanner for product SKU.")
    }
}
