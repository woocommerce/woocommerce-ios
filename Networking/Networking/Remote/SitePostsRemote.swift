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
        let path = String(format: "/sites/%@/posts/%@", siteID, postID)
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: path)
        let mapper = SitePostMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}
