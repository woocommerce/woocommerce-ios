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
    
    init(metadata: OrderMetaData) {
        self.id = metadata.metadataID
        self.title = metadata.key
        self.content = metadata.value
    }
}
