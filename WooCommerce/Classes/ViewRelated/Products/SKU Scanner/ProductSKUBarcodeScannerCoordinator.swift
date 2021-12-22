import Experiments
import UIKit

/// Coordinates navigation for product SKU barcode scanner based on camera permission.
final class ProductSKUBarcodeScannerCoordinator: Coordinator {
    var navigationController: UINavigationController
    private let permissionChecker: CaptureDevicePermissionChecker
    private let onSKUBarcodeScanned: (_ barcode: String) -> Void

    init(sourceNavigationController: UINavigationController,
         permissionChecker: CaptureDevicePermissionChecker = AVCaptureDevicePermissionChecker(),
         onSKUBarcodeScanned: @escaping (_ barcode: String) -> Void) {
        self.navigationController = sourceNavigationController
        self.permissionChecker = permissionChecker
        self.onSKUBarcodeScanned = onSKUBarcodeScanned
    }

    func start() {
        let cameraAuthorizationStatus = permissionChecker.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
        case .denied, .restricted:
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
        let scannerViewController = ProductSKUInputScannerViewController(onBarcodeScanned: { [weak self] barcode in
            self?.onSKUBarcodeScanned(barcode)
            self?.navigationController.popViewController(animated: true)
        })
        navigationController.show(scannerViewController, sender: self)
    }
}
