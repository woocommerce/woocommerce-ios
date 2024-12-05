import Foundation
import UIKit

protocol BuiltInCardReaderMerchantEducationPresenting {
    func presentMerchantEducation(completion: @escaping () -> Void)
}

final class BuiltInCardReaderMerchantEducationPresenter: BuiltInCardReaderMerchantEducationPresenting {
    private weak var rootViewController: UIViewController?

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    func presentMerchantEducation(completion: @escaping () -> Void) {
        let viewController = TapToPayEducationViewHostingController(onDismiss: completion)
        let topViewController = rootViewController?.topmostPresentedViewController
        topViewController?.present(viewController, animated: true)
    }
}
