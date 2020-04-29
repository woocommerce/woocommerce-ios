import Foundation
import Alamofire


/// WP.com Site Posts API: Remote Endpoints
///
public class SitePostsRemote: Remote {


    /// Loads the Post by ID from WP.com
    ///
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the post.
    ///   - postID: Id of the post that we want to fetch
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadSitePost(for siteID: Int64, postID: Int64, completion: @escaping (SitePost?, Error?) -> Void) {
        let path = String(format: "/sites/%d/posts/%d", siteID, postID)
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        let mapper = SitePostMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
    
    /// Update a post from WP.com
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll update the post.
    ///     - postID: Id of the post that we want to update
    ///     - post: SitePost that we will use to update the post.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateSitePost(for siteID: Int64, postID: Int64, post: SitePost, completion: @escaping (SitePost?, Error?) -> Void) {
        do {
            let parameters = try post.toDictionary()
            let path = String(format: "/sites/%d/posts/%d", siteID, postID)
            let request = DotcomRequest(wordpressApiVersion: .mark1_2, method: .post, path: path, parameters: parameters)
            let mapper = SitePostMapper()
            
            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(nil, error)
        }
    }
}
