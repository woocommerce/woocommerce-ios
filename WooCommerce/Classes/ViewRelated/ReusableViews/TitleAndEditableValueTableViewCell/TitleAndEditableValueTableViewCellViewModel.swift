import Foundation

/// Observable ViewModel for `TitleAndEditableValueTableViewCell`.
///
final class TitleAndEditableValueTableViewCellViewModel {

    let title: String?
    let placeholder: String?

    private let valueSubject = BehaviorSubject<String?>(nil)

    var value: Observable<String?> {
        valueSubject
    }

    var currentValue: String? {
        valueSubject.value
    }

    init(title: String?, placeholder: String?) {
        self.title = title
        self.placeholder = placeholder
    }

    func update(value: String?) {
        valueSubject.send(value)
    }
}
