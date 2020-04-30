import Networking

/// MARK: SitePostStore
///
final public class SitePostStore: Store {
    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: SitePostAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? SitePostAction else {
            assertionFailure("\(String(describing: self)) received an unsupported action")
            return
        }

        switch action {
        case .retrieveSitePostPassword(let siteID, let postID, let onCompletion):
            retrieveSitePostPassword(siteID: siteID, postID: postID, onCompletion: onCompletion)
        case .updateSitePostPassword(let siteID, let postID, let password, let onCompletion):
            updateSitePostPassword(siteID: siteID, postID: postID, password: password, onCompletion: onCompletion)
        }
    }
}

// MARK: - Services!
//
private extension SitePostStore {

    /// Retrieve the password for a specific site post from WP.com
    ///
    func retrieveSitePostPassword(siteID: Int64, postID: Int64, onCompletion: @escaping (_ password: String?, _ error: Error?) -> Void) {
        let remote = SitePostsRemote(network: network)
        remote.loadSitePost(for: siteID, postID: postID) { (sitePost, error) in
            guard error == nil else {
                onCompletion(nil, error)
                return
            }
            onCompletion(sitePost?.password, nil)
        }
    }

    /// Update the password for a specific site post from WP.com
    ///
    func updateSitePostPassword(siteID: Int64, postID: Int64, password: String, onCompletion: @escaping (_ password: String?, _ error: Error?) -> Void) {
        let remote = SitePostsRemote(network: network)
        let newSitePost = SitePost(siteID: siteID, password: password)
        remote.updateSitePost(for: siteID, postID: postID, post: newSitePost) { (sitePost, error) in
            guard error == nil else {
                onCompletion(nil, error)
                return
            }
            onCompletion(sitePost?.password, nil)
        }
    }
}
