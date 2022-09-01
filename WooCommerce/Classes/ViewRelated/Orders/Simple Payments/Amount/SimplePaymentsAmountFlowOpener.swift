import Foundation
import UIKit
import Combine

/// Triggers the simple payments amount flow given a navigation controller and a site id
/// 
final class SimplePaymentsAmountFlowOpener {
    static func openSimplePaymentsAmountFlow(from navigationController: UINavigationController, siteID: Int64) {
        let presentNoticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let viewModel = SimplePaymentsAmountViewModel(siteID: siteID, presentNoticeSubject: presentNoticeSubject)

        let viewController = SimplePaymentsAmountHostingController(viewModel: viewModel, presentNoticePublisher: presentNoticeSubject.eraseToAnyPublisher())
        let simplePaymentsNC = WooNavigationController(rootViewController: viewController)
        navigationController.present(simplePaymentsNC, animated: true)

       ServiceLocator.analytics.track(event: WooAnalyticsEvent.SimplePayments.simplePaymentsFlowStarted())
    }
}
