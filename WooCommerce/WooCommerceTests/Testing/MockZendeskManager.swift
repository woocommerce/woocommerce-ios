
import Foundation
import UIKit
import enum Networking.NetworkError

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

    /// Tracks which custom fields were invoked via the create request method.
    ///
    private(set) var latestInvokedCustomFields: [Int64: String] = [:]

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

    let zendeskEnabled = false

    private(set) var haveUserIdentity: Bool = false
    private var stubbedName: String?
    private var stubbedEmailAddress: String?
    private var stubbedCreateIdentityResult: Result<Void, Error>?
    private var stubbedCreateSupportRequestResult: Result<Void, Error>?

    func retrieveUserInfoIfAvailable() -> (name: String?, emailAddress: String?) {
        (stubbedName, stubbedEmailAddress)
    }

    func createIdentity(name: String, email: String) async throws {
        guard let stubbedCreateIdentityResult else {
            throw NetworkError.notFound()
        }
        switch stubbedCreateIdentityResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
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

    func mockIdentity(name: String?, email: String?, haveUserIdentity: Bool) {
        stubbedName = name
        stubbedEmailAddress = email
        self.haveUserIdentity = haveUserIdentity
    }

    func whenCreateIdentity(thenReturn result: Result<Void, Error>) {
        stubbedCreateIdentityResult = result
    }

    func whenCreateSupportRequest(thenReturn result: Result<Void, Error>) {
        stubbedCreateSupportRequestResult = result
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
        latestInvokedCustomFields = customFields
        if let stubbedCreateSupportRequestResult {
            onCompletion(stubbedCreateSupportRequestResult)
        }
    }
}
