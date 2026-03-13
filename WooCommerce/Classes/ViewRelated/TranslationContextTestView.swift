import UIKit

/// Test view for exercising translation context suggestions.
/// This file is intentionally added to test the translation context Danger plugin.
final class TranslationContextTestView: UIView {

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Localization.save, for: .normal)
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = Localization.processing
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = Localization.settingsTitle
        return label
    }()

    private lazy var noteTextField: UITextField = {
        let field = UITextField()
        field.placeholder = Localization.notePlaceholder
        return field
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .close)
        button.accessibilityLabel = Localization.close
        return button
    }()

    private lazy var draftBadge: UILabel = {
        let label = UILabel()
        label.text = Localization.draftStatus
        label.font = .preferredFont(forTextStyle: .caption1)
        return label
    }()
}

private extension TranslationContextTestView {
    enum Localization {
        static let save = NSLocalizedString(
            "test_order_action_save",
            value: "Save",
            comment: "Button title"
        )

        static let processing = NSLocalizedString(
            "test_order_status_processing",
            value: "Processing",
            comment: ""
        )

        static let settingsTitle = NSLocalizedString(
            "test_store_settings_title",
            value: "Settings",
            comment: "Screen title"
        )

        static let notePlaceholder = NSLocalizedString(
            "test_product_note_placeholder",
            value: "Add a note",
            comment: ""
        )

        static let close = NSLocalizedString(
            "test_shipping_label_close",
            value: "Close",
            comment: ""
        )

        static let draftStatus = NSLocalizedString(
            "test_order_draft_status",
            value: "Draft",
            comment: ""
        )
    }
}
