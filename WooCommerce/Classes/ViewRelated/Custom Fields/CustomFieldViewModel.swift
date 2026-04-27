import Foundation
import UIKit
import Yosemite

/// ViewModel for an individual custom field
struct CustomFieldViewModel: Identifiable, Equatable {
    /// Unique identifier, required by `SwiftUI`
    ///
    let id = UUID()

    let fieldID: Int64?

    /// The key for the Custom Field
    ///
    let key: String

    /// The value for the Custom Field
    ///
    let value: String

    /// Optional URL used for linking the Custom Field value
    ///
    let valueURL: URL?

    let isJson: Bool

    init(fieldID: Int64? = nil, key: String, value: String, valueURL: URL? = nil, isJson: Bool = false) {
        self.fieldID = fieldID
        self.key = key
        self.value = value
        self.valueURL = valueURL
        self.isJson = isJson
    }

    init(metadata: MetaData) {
        // Create a URL out of the metadata value, if it is a valid URL that can be opened on device
        var valueURL: URL?
        if metadata.value.stringValue.isValidURL(), let url = URL(string: metadata.value.stringValue), UIApplication.shared.canOpenURL(url) {
            valueURL = url
        }

        self.init(
            fieldID: metadata.metadataID,
            key: metadata.key,
            value: metadata.value.stringValue,
            valueURL: valueURL,
            isJson: metadata.value.isJson
        )
    }

    func asDictionary() -> [String: Any] {
        var json: [String: Any] = [:]
            if let fieldID {
                json["id"] = fieldID
            }
            json["key"] = key
            json["value"] = value
        return json
    }
}
