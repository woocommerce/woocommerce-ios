import Foundation
import Alamofire


/// WP.com Site Posts API: Remote Endpoints
///
public class SitePostsRemote: Remote {


    /// Loads the Post by ID from WP.com
    /// https://developer.wordpress.com/docs/api/1.1/get/sites/%24site/posts/%24post_ID/
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the post.
    ///   - postID: Id of the post that we want to fetch.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSitePost(for siteID: Int64, postID: Int64, completion: @escaping (Post?, Error?) -> Void) {
        let path = String(format: "/sites/%d/posts/%d", siteID, postID)
        let parameters = ["fields": "site_ID,password"]
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path, parameters: parameters)
        let mapper = PostMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Update a post from WP.com
    /// https://developer.wordpress.com/docs/api/1.2/post/sites/%24site/posts/%24post_ID/
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll update the post.
    ///     - postID: Id of the post that we want to update.
    ///     - post: Post that we will use to update the post.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateSitePost(for siteID: Int64, postID: Int64, post: Post, completion: @escaping (Post?, Error?) -> Void) {
        do {
            var parameters = try post.toDictionary()
            let parametersFields = ["fields": "site_ID,password"]
            parameters.merge(parametersFields) { (current, _) in current }
            let path = String(format: "/sites/%d/posts/%d", siteID, postID)
            let request = DotcomRequest(wordpressApiVersion: .mark1_2, method: .post, path: path, parameters: parameters)
            let mapper = PostMapper()

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(nil, error)
        }
    }
}
