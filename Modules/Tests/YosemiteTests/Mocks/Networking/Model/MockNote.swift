
import Foundation
import XCTest

import Networking

/// Provides builders for `Note` to use as test data.
///
struct MockNote {
    func make(noteID: Int64 = 0,
              metaSiteID: Int64? = nil,
              metaReviewID: Int64? = nil) -> Note {

        let metaAsData: Data = {
            var ids = [String: Int64]()
            if let siteID = metaSiteID {
                ids[MetaContainer.Keys.site.rawValue] = siteID
            }
            if let reviewID = metaReviewID {
                ids[MetaContainer.Keys.comment.rawValue] = reviewID
            }

            if ids.isEmpty {
                return Data()
            } else {
                var metaAsJSON = [String: [String: Int64]]()
                metaAsJSON[MetaContainer.Containers.ids.rawValue] = ids
                do {
                    return try JSONEncoder().encode(metaAsJSON)
                } catch {
                    fatalError("Expected to convert MetaContainer JSON to Data. \(error)")
                }
            }
        }()

        return Note(noteID: noteID,
                    hash: 0,
                    read: false,
                    icon: nil,
                    noticon: nil,
                    timestamp: "",
                    type: "",
                    subtype: nil,
                    url: nil,
                    title: nil,
                    subject: Data(),
                    header: Data(),
                    body: Data(),
                    meta: metaAsData)
    }
}
