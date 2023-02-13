
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

    func showTicketListIfPossible(from controller: UIViewController, with sourceTag: String?) {
        // no-op
    }

    func showTicketListIfPossible(from controller: UIViewController) {
        // no-op
    }

    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping onUserInformationCompletion) {
        // no-op
    }

    func getTags(supportSourceTag: String?) -> [String] {
        []
    }

    func initialize() {
        // no-op
    }

    func reset() {
        // no-op
    }

    func observeStoreSwitch() {
        // no-op
    }

    func fetchSystemStatusReport() {
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
        // no-op
    }

    func formID() -> Int64 {
        .zero
    }

    func wcPayFormID() -> Int64 {
        .zero
    }

    func generalTags() -> [String] {
        []
    }

    func wcPayTags() -> [String] {
        []
    }

    func generalCustomFields() -> [Int64: String] {
        [:]
    }

    func wcPayCustomFields() -> [Int64: String] {
        [:]
    }
}

extension MockZendeskManager: SupportManagerAdapter {
    /// Executed whenever the app receives a Push Notifications Token.
    ///
    func deviceTokenWasReceived(deviceToken: String) {
        // no-op
    }

    /// Executed whenever the app should unregister for Remote Notifications.
    ///
    func unregisterForRemoteNotifications() {
        // no-op
    }

    /// Executed whenever the app receives a Remote Notification.
    ///
    func pushNotificationReceived() {
        // no-op
    }

    /// Executed whenever the a user has tapped on a Remote Notification.
    ///
    func displaySupportRequest(using userInfo: [AnyHashable: Any]) {
        // no-op
    }
}
