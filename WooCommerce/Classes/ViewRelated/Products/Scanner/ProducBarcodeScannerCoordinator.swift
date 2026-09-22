import AVFoundation
import Experiments
import UIKit

/// Coordinates navigation for product barcode scanner based on camera permission.
final class ProducBarcodeScannerCoordinator: Coordinator {
    typealias FailureReason = WooAnalyticsEvent.BarcodeScanning.BarcodeScanningFailureReason

    let navigationController: UINavigationController
    private let permissionChecker: CaptureDevicePermissionChecker
    private let onBarcodeScanned: (_ barcode: ScannedBarcode) -> Void
    private let onPermissionsDenied: ((FailureReason) -> Void)?
    private let onOpenSettings: ((FailureReason) -> Void)?

    init(sourceNavigationController: UINavigationController,
         permissionChecker: CaptureDevicePermissionChecker = AVCaptureDevicePermissionChecker(),
         onBarcodeScanned: @escaping (_ barcode: ScannedBarcode) -> Void,
         onPermissionsDenied: ((FailureReason) -> Void)? = nil,
         onOpenSettings: ((FailureReason) -> Void)? = nil) {
        self.navigationController = sourceNavigationController
        self.permissionChecker = permissionChecker
        self.onBarcodeScanned = onBarcodeScanned
        self.onPermissionsDenied = onPermissionsDenied
        self.onOpenSettings = onOpenSettings
    }

    func start() {
        let cameraAuthorizationStatus = permissionChecker.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
        case .denied, .restricted:
            let failureReason = FailureReason(authorizationStatus: cameraAuthorizationStatus)
            if let failureReason {
                onPermissionsDenied?(failureReason)
            }
            UIAlertController.presentBarcodeScannerNoCameraPermissionAlert(viewController: navigationController,
                                                                          onOpenSettings: { [weak self] in
                guard let failureReason else { return }
                self?.onOpenSettings?(failureReason)
            }, onCancel: { [weak self] in
                self?.navigationController.dismiss(animated: true, completion: nil)
            })
        case .notDetermined:
            permissionChecker.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    showScanner()
                } else {
                    onPermissionsDenied?(.cameraAccessDeniedAtPrompt)
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
