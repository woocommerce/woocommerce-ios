
import Foundation
import UIKit

@testable import WooCommerce

final class MockZendeskManager: ZendeskManagerProtocol {

    struct NewRequestIfPossibleInvocation {
        let controller: UIViewController
        let sourceTag: String?
    }

    /// The invocations of `showNewRequestIfPossible` with the passed arguments.
    ///
    /// The number of elements match the number of invocations.
    ///
    private(set) var newRequestIfPossibleInvocations = [NewRequestIfPossibleInvocation]()

    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: String?) {
        let invocation = NewRequestIfPossibleInvocation(controller: controller, sourceTag: sourceTag)
        newRequestIfPossibleInvocations.append(invocation)
    }
}
