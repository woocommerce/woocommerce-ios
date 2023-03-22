
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

    /// Tracks which tags were invoked via the create request method.
    ///
    private(set) var latestInvokedTags: [String] = []

    func showNewRequestIfPossible(from controller: UIViewController, with sourceTag: String?) {
        let invocation = NewRequestIfPossibleInvocation(controller: controller, sourceTag: sourceTag)
        newRequestIfPossibleInvocations.append(invocation)
    }

    func showNewWCPayRequestIfPossible(from controller: UIViewController, with sourceTag: String?) {
        let invocation = NewRequestIfPossibleInvocation(controller: controller, sourceTag: sourceTag)
        newRequestIfPossibleInvocations.append(invocation)
    }

    func showNewRequestIfPossible(from controller: UIViewController) {
        showNewRequestIfPossible(from: controller, with: nil)
    }

    func showNewWCPayRequestIfPossible(from controller: UIViewController) {
        showNewWCPayRequestIfPossible(from: controller, with: nil)
    }

    var zendeskEnabled = false

    func userSupportEmail() -> String? {
        return nil
    }

    func showHelpCenter(from controller: UIViewController) {
        // no-op
    }

    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping onUserInformationCompletion) {
        // no-op
    }

    func initialize() {
        // no-op
    }

    func reset() {
        // no-op
    }
}

extension MockZendeskManager {
    func createIdentity(presentIn viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        // no-op
    }

    func createSupportRequest(formID: Int64,
                              customFields: [Int64: String],
                              tags: [String],
                              subject: String,
                              description: String,
                              onCompletion: @escaping (Result<Void, Error>) -> Void) {
        latestInvokedTags = tags
    }
}
