import Foundation
import UIKit

protocol CardReaderModalFlowViewControllerProtocol: UIViewController {
    func prepareForCardReaderModalFlow()
}

extension CardReaderModalFlowViewControllerProtocol {
    func prepareForCardReaderModalFlow() {
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .grayTransparentOverlay
        modalTransitionStyle = .coverVertical
    }
}

private extension UIColor {
    static let grayTransparentOverlay = UIColor.black.withAlphaComponent(0.5)
}
