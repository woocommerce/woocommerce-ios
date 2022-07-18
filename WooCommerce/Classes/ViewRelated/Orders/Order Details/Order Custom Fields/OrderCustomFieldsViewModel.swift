import Foundation
import Yosemite

/// ViewModel for `OrderCustomFieldsDetails`
struct OrderCustomFieldsViewModel: Identifiable {
    /// Unique identifier, required by `SwiftUI`
    ///
    let id: Int64

    /// The title for the Custom Field mapped from the metadata key
    ///
    let title: String

    /// The content for the Custom Field mapped from the metadata value
    ///
    let content: String

    /// Optional URL used for linking the Custom Field content
    ///
    let contentURL: URL?

    init(id: Int64, title: String, content: String, contentURL: URL? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.contentURL = contentURL

    }

    init(metadata: OrderMetaData) {
        // Create a URL out of the metadata value, if it is a valid URL that can be opened on device
        var contentURL: URL?
        if metadata.value.isValidURL(), let url = URL(string: metadata.value), UIApplication.shared.canOpenURL(url) {
            contentURL = url
        }

        self.init(
            id: metadata.metadataID,
            title: metadata.key,
            content: metadata.value.removedHTMLTags,
            contentURL: contentURL
        )
    }
}
