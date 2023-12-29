import UIKit
import SwiftUI

struct ProductLoaderView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UINavigationController

    let model: ProductLoaderViewController.Model
    let siteID: Int64
    let forceReadOnly: Bool

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = ProductLoaderViewController(model: model,
                                                         siteID: siteID,
                                                         forceReadOnly: forceReadOnly)
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // nothing to do here
    }
}
