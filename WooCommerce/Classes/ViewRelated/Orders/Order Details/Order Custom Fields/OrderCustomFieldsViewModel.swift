import Foundation
import Yosemite

/// ViewModel for `OrderCustomFieldsDetails`
struct OrderCustomFieldsViewModel: Identifiable {
    let id: Int64

    /// The title for the Custom Field mapped from the metadata key
    ///
    let title: String

    /// The content for the Custom Field mapped from the metadata value
    ///
    let content: String

    init(id: Int64, title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }

    init(metadata: OrderMetaData) {
        self.init(
            id: metadata.metadataID,
            title: metadata.key,
            content: metadata.value
        )
    }
}
