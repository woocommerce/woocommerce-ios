import Codegen
import XCTest
import Yosemite


final class ProductReviewFromNoteParcelFactory {
    func parcel(metaSiteID: Int64 = 0) -> ProductReviewFromNoteParcel {
        let metaAsData: Data = {
            var ids = [String: Int64]()
            ids[MetaContainer.Keys.site.rawValue] = metaSiteID

            var metaAsJSON = [String: [String: Int64]]()
            metaAsJSON[MetaContainer.Containers.ids.rawValue] = ids
            do {
                return try JSONEncoder().encode(metaAsJSON)
            } catch {
                XCTFail("Expected to convert MetaContainer JSON to Data. \(error)")
                return Data()
            }
        }()

        let note = Note(noteID: 1,
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
        return ProductReviewFromNoteParcel.fake().copy(note: note)
    }
}
