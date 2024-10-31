import Foundation
import Yosemite

/// ViewModel for an individual custom field
struct CustomFieldViewModel: Identifiable {
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

    var isJson: Bool {
        (try? JSONSerialization.jsonObject(with: value.data(using: .utf8) ?? Data())) != nil
    }

    init(id: Int64? = nil, key: String, value: String, valueURL: URL? = nil) {
        self.fieldID = id
        self.key = key
        self.value = value
        self.valueURL = valueURL

    }

    init(metadata: MetaData) {
        // Create a URL out of the metadata value, if it is a valid URL that can be opened on device
        var valueURL: URL?
        if metadata.value.isValidURL(), let url = URL(string: metadata.value), UIApplication.shared.canOpenURL(url) {
            valueURL = url
        }

        self.init(
            id: metadata.metadataID,
            key: metadata.key,
            value: metadata.value,
            valueURL: valueURL
        )
    }

    func asDictionary() -> [String: Any] {
        var json: [String: Any] = [:]
            if let fieldID = fieldID {
                json["id"] = fieldID
            }
            json["key"] = key
            json["value"] = value
        return json
    }
}
