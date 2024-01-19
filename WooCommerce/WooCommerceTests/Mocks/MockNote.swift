import Foundation
import XCTest

import Networking

/// Note: based on `YosemiteTests.MockNote`.
/// Provides builders for `Note` to use as test data since `MetaContainer` cannot be initialized easily.
///
struct MockNote {
    func makeOrderNote(noteID: Int64 = 0,
                       metaSiteID: Int64,
                       metaOrderID: Int64) -> Note {
        let metaAsData: Data = {
            var ids = [String: Int64]()
            ids[MetaContainer.Keys.site.rawValue] = metaSiteID
            ids[MetaContainer.Keys.order.rawValue] = metaOrderID

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
                    type: Note.Kind.storeOrder.rawValue,
                    subtype: nil,
                    url: nil,
                    title: nil,
                    subject: Data(),
                    header: Data(),
                    body: Data(),
                    meta: metaAsData)
    }
}
