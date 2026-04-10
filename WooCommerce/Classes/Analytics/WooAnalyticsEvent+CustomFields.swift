import Foundation
import enum Networking.MetaDataType

extension WooAnalyticsEvent {
    enum CustomFields {
        /// Event property keys
        private enum Keys {
            static let type = "type"
            static let fieldsCount = "fields_count"
            static let fieldsSize = "fields_size"
            static let hasJsonFields = "has_json_fields"
            static let isJson = "is_json"
            static let has_html = "has_html"
            static let editedFielsdCount = "edited_fields_count"
            static let addedFieldsCount = "added_fields_count"
            static let deletedFieldsCount = "deleted_fields_count"
            static let errorContext = "error_context"
            static let errorDescription = "error_description"
        }

        enum EditorType: String {
            case edit = "edit"
            case new = "new"
        }

        enum EditorPicker: String {
            case text = "text"
            case aztec = "aztec"
        }


        /// Tracked when the Custom Fields List view is opened
        static func customFieldsListLoaded(
            type: String,
            fieldsCount: Int64,
            fieldsSize: Int64,
            has_json_fields: Bool
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldsListLoaded,
                              properties: [
                                Keys.type: type,
                                Keys.fieldsCount: fieldsCount,
                                Keys.fieldsSize: fieldsSize,
                                Keys.hasJsonFields: has_json_fields
                              ])
        }

        /// Tracked when a single Custom Field in the list is tapped
        static func customFieldTapped(isJson: Bool, hasHtml: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldTapped,
                              properties: [
                                Keys.isJson: isJson,
                                Keys.has_html: hasHtml
                              ])
        }

        /// Tracked when the add custom field button is tapped
        static func addCustomFieldTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .addCustomFieldTapped,
                              properties: [:])
        }

        /// Tracked when the save custom field button is tapped
        static func saveCustomFieldTapped(
            editedFieldsCount: Int,
            addedFieldsCount: Int,
            deletedFieldsCount: Int
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .saveCustomFieldTapped,
                              properties: [
                                Keys.editedFielsdCount: editedFieldsCount,
                                Keys.addedFieldsCount: addedFieldsCount,
                                Keys.deletedFieldsCount: deletedFieldsCount
                              ])
        }

        /// Tracked when save custom fields action is completed successfully
        static func customFieldsSavedSuccessfully() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldsSavedSuccessfully,
                              properties: [:])
        }

        /// Tracked when save custom fields action is failed
        static func customFieldsSavingFailed(errorContext: String, errorDescription: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldsSavingFailed,
                              properties: [
                                Keys.errorContext: errorContext,
                                Keys.errorDescription: errorDescription
                              ])
        }

        /// Tracked when Custom Field Editor is loaded
        static func customFieldEditorLoaded(editorType: EditorType) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldEditorLoaded,
                              properties: [
                                Keys.type: editorType.rawValue,
                              ])
        }

        /// Tracked when Custom Field Editor picker is tapped
        static func customFieldEditorPickerTapped(pickerType: EditorPicker) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldEditorPickerTapped,
                              properties: [
                                Keys.type: pickerType.rawValue,
                              ])
        }

        /// Tracked when Custom Field Editor Delete button is tapped
        static func customFieldEditorDeleteTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldEditorDeleteTapped,
                              properties: [:])
        }

        /// Tracked when Custom Field Editor Done button is tapped
        static func customFieldEditorDoneTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .customFieldEditorDoneTapped,
                              properties: [:])
        }


    }
}

extension MetaDataType {
    var analyticsValue: String {
        switch self {
        case .order:
            return "order"
        case .product:
            return "product"
        }
    }
}
