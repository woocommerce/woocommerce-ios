import Foundation

/// Observable ViewModel for `TitleAndEditableValueTableViewCell`.
///
final class TitleAndEditableValueTableViewCellViewModel {

    let title: String?
    let placeholder: String?
    let allowsEditing: Bool

    private let valueSubject: BehaviorSubject<String?>

    var value: Observable<String?> {
        valueSubject
    }

    var currentValue: String? {
        valueSubject.value
    }

    init(title: String?, placeholder: String?, initialValue: String? = nil, allowsEditing: Bool = true) {
        self.title = title
        self.placeholder = placeholder
        self.allowsEditing = allowsEditing

        valueSubject = BehaviorSubject(initialValue)
    }

    func update(value: String?) {
        valueSubject.send(value)
    }
}
