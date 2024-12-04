import Foundation
import UIKit
import WordPressUI

protocol BuiltInCardReaderMerchantEducationPresenting {
    func presentMerchantEducation(completion: @escaping () -> Void)
}

final class BuiltInCardReaderMerchantEducationPresenter: BuiltInCardReaderMerchantEducationPresenting {
    private weak var rootViewController: UIViewController?

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    func presentMerchantEducation(completion: @escaping () -> Void) {
        let viewController = TapToPayEducationViewViewHostingController(onDismiss: completion)
        let topViewController = rootViewController?.topmostPresentedViewController
        topViewController?.present(viewController, animated: true)
    }
}
