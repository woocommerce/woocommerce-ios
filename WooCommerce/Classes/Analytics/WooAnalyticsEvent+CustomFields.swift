import Foundation

extension WooAnalyticsEvent {
    enum CustomFields {
        /// Event property keys
        private enum Keys {
            static let type = "type"
            static let fieldsCount = "field_count"
            static let fieldsSize = "fields_size"
            static let hasJsonFields = "has_json_fields"
            static let isJson = "is_json"
            static let has_html = "has_html"
            static let editedFieldCount = "edited_field_count"
            static let addedFieldCount = "added_field_count"
            static let deletedFieldCount = "deleted_field_count"
        }

        enum EditorType: String {
            case edit = "edit"
            case new = "new"
        }

        enum EditorPicker: String {
            case text = "text"
            case aztec = "aztec"
        }
    }
}
