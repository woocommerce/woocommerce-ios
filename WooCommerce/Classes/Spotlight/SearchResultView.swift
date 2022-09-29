import SwiftUI
import UIKit
import CoreData
import Storage

/// SwiftUI conformance for `SettingsViewController`
///
struct SearchResultView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SearchResultViewController
    let searchResultObject: NSManagedObject

    class Coordinator {
        var parentObserver: NSKeyValueObservation?
    }

    ///
    func makeUIViewController(context: Self.Context) -> SearchResultViewController {
        SearchResultViewController(searchResultObject: searchResultObject)
    }

    func updateUIViewController(_ uiViewController: SearchResultViewController, context: Context) {
        // nothing to do here
    }

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}

final class SearchResultViewController: UIViewController {
    let searchResultObject: NSManagedObject

    init(searchResultObject: NSManagedObject) {
        self.searchResultObject = searchResultObject

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let product = searchResultObject as? Storage.Product {
            presentProduct(product)
        } else if let order = searchResultObject as? Storage.Order {
            presentOrder(order)
        }
    }

    private func presentOrder(_ order: Storage.Order) {
        let loaderViewController = OrderLoaderViewController(orderID: order.orderID, siteID: Int64(order.siteID))

        addChild(loaderViewController)

        loaderViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loaderViewController.view)
        view.pinSubviewToAllEdges(loaderViewController.view)
        loaderViewController.didMove(toParent: self)
    }

    private func presentProduct(_ product: Storage.Product) {
        ProductDetailsFactory.productDetails(product: product.toReadOnly(),
                                             presentationStyle: .navigationStack,
                                             forceReadOnly: false) { [weak self] viewController in
            self?.addChild(viewController)

            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            self?.view.addSubview(viewController.view)
            self?.view.pinSubviewToAllEdges(viewController.view)
            viewController.didMove(toParent: self)
        }
    }

}
