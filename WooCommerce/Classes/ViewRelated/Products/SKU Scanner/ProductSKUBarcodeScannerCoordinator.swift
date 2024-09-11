import Experiments
import UIKit

/// Coordinates navigation for product SKU barcode scanner based on camera permission.
final class ProductSKUBarcodeScannerCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let permissionChecker: CaptureDevicePermissionChecker
    private let onSKUBarcodeScanned: (_ barcode: ScannedBarcode) -> Void
    private let onPermissionsDenied: (() -> Void)?

    init(sourceNavigationController: UINavigationController,
         permissionChecker: CaptureDevicePermissionChecker = AVCaptureDevicePermissionChecker(),
         onSKUBarcodeScanned: @escaping (_ barcode: ScannedBarcode) -> Void,
         onPermissionsDenied: (() -> Void)? = nil) {
        self.navigationController = sourceNavigationController
        self.permissionChecker = permissionChecker
        self.onSKUBarcodeScanned = onSKUBarcodeScanned
        self.onPermissionsDenied = onPermissionsDenied
    }

    func start() {
        let cameraAuthorizationStatus = permissionChecker.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
        case .denied, .restricted:
            onPermissionsDenied?()
            UIAlertController.presentBarcodeScannerNoCameraPermissionAlert(viewController: navigationController) { [weak self] in
                self?.navigationController.dismiss(animated: true, completion: nil)
            }
        case .notDetermined:
            permissionChecker.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.showSKUScanner()
                }
            }
        default:
            showSKUScanner()
        }
    }
}

private extension ProductSKUBarcodeScannerCoordinator {
    func showSKUScanner() {
        let scannerViewController = SKUCodeScannerProvider.SKUCodeScanner(onBarcodeScanned: { [weak self] barcode in
            self?.onSKUBarcodeScanned(barcode)
            self?.navigationController.dismiss(animated: true)
        })

        navigationController.present(scannerViewController, animated: true)
    }
}
