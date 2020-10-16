import Foundation

/// Observable ViewModel for `TitleAndEditableValueTableViewCell`.
///
/// Represents a view that has a title label and an editable text field.
///
final class TitleAndEditableValueTableViewCellViewModel {

    /// The `String` used for the title label.
    let title: String?
    /// The placeholder for the editable text field.
    let placeholder: String?
    /// If `false`, the text field will be disabled. Defaults to `true`.
    let allowsEditing: Bool

    private let valueSubject: BehaviorSubject<String?>

    /// Emits values whenever the text field changes.
    ///
    /// This is connected with the view's text field through the `update(value:)`.
    var value: Observable<String?> {
        valueSubject
    }

    /// The last value of the text field.
    var currentValue: String? {
        valueSubject.value
    }

    init(title: String?, placeholder: String? = nil, initialValue: String? = nil, allowsEditing: Bool = true) {
        self.title = title
        self.placeholder = placeholder
        self.allowsEditing = allowsEditing

        valueSubject = BehaviorSubject(initialValue)
    }

    /// Updates the value of the `self.value` `Observable`.
    ///
    /// This is generally used by the view represented by this `ViewModel`.
    func update(value: String?) {
        valueSubject.send(value)
    }
}
