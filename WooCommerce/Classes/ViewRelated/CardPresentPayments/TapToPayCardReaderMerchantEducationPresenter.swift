import Foundation
import SwiftUI
import UIKit

protocol TapToPayCardReaderMerchantEducationPresenting {
    func presentMerchantEducation(completion: @escaping () -> Void)
}

final class TapToPayCardReaderMerchantEducationPresenter: @preconcurrency TapToPayCardReaderMerchantEducationPresenting {
    private weak var rootViewController: ViewControllerPresenting?

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    @MainActor func presentMerchantEducation(completion: @escaping () -> Void) {
        let viewController = UIHostingController(rootView: TapToPayEducationView(viewModel: .init(completion: { _ in
            completion()
        })))
        let topViewController = rootViewController?.presentedViewController
        topViewController?.present(viewController, animated: true)
    }
}
