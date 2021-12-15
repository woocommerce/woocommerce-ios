import AVFoundation
import Experiments
import UIKit

final class ProductSKUBarcodeScannerCoordinator: Coordinator {
    var navigationController: UINavigationController
    private let onSKUBarcodeScanned: (_ barcode: String) -> Void

    init(sourceNavigationController: UINavigationController, onSKUBarcodeScanned: @escaping (_ barcode: String) -> Void) {
        self.navigationController = sourceNavigationController
        self.onSKUBarcodeScanned = onSKUBarcodeScanned
    }

    func start() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
        case .denied:
            UIAlertController.presentBarcodeScannerNoCameraPermissionAlert(viewController: navigationController) { [weak self] in
                self?.navigationController.dismiss(animated: true, completion: nil)
            }
        default:
            let scannerViewController = ProductSKUInputScannerViewController(onBarcodeScanned: { [weak self] barcode in
                self?.onSKUBarcodeScanned(barcode)
                self?.navigationController.popViewController(animated: true)
            })
            navigationController.show(scannerViewController, sender: self)
        }
    }
}
