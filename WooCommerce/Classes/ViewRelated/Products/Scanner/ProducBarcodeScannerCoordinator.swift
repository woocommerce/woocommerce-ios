import Experiments
import UIKit

/// Coordinates navigation for product barcode scanner based on camera permission.
final class ProducBarcodeScannerCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let permissionChecker: CaptureDevicePermissionChecker
    private let onBarcodeScanned: (_ barcode: ScannedBarcode) -> Void
    private let onPermissionsDenied: (() -> Void)?

    init(sourceNavigationController: UINavigationController,
         permissionChecker: CaptureDevicePermissionChecker = AVCaptureDevicePermissionChecker(),
         onBarcodeScanned: @escaping (_ barcode: ScannedBarcode) -> Void,
         onPermissionsDenied: (() -> Void)? = nil) {
        self.navigationController = sourceNavigationController
        self.permissionChecker = permissionChecker
        self.onBarcodeScanned = onBarcodeScanned
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
                    self?.showScanner()
                }
            }
        default:
            showScanner()
        }
    }
}

private extension ProducBarcodeScannerCoordinator {
    func showScanner() {
        let scannerViewController = ProductBarcodeScannerProvider.barcodeScanner(onBarcodeScanned: { [weak self] barcode in
            self?.onBarcodeScanned(barcode)
            self?.navigationController.dismiss(animated: true)
        })

        navigationController.present(scannerViewController, animated: true)
    }
}
