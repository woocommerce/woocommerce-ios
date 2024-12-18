import Foundation
import SwiftUI
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
        let viewController = UIHostingController(rootView: TapToPayEducationView(viewModel: .init(completion: { _ in
            completion()
        })))
        let topViewController = rootViewController?.presentedViewController
        topViewController?.present(viewController, animated: true)
    }
}
