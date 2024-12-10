import Foundation
import UIKit

protocol BuiltInCardReaderMerchantEducationPresenting {
    func presentMerchantEducation(completion: @escaping () -> Void)
}

final class BuiltInCardReaderMerchantEducationPresenter: BuiltInCardReaderMerchantEducationPresenting {
    private weak var rootViewController: ViewControllerPresenting?

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    func presentMerchantEducation(completion: @escaping () -> Void) {
        let viewController = TapToPayEducationViewHostingController(onDismiss: completion)
        let topViewController = rootViewController?.presentedViewController
        topViewController?.present(viewController, animated: true)
    }
}
