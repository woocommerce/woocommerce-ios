import Combine
import StoreDesignSystem
import SwiftUI
import UIKit

@MainActor
final class SearchViewControllerSearchFieldModel: ObservableObject {
    @Published var query = ""
    @Published var actionTitle = ""
    @Published var shouldFocus = false

    var queryChanges: AnyPublisher<String, Never> {
        $query
            .removeDuplicates()
            .dropFirst()
            .eraseToAnyPublisher()
    }
}

struct SearchViewControllerSearchField: View {
    @ObservedObject var model: SearchViewControllerSearchFieldModel
    let placeholder: String
    let returnKeyType: UIReturnKeyType
    let hidesAction: Bool
    let searchFieldAccessibilityIdentifier: String
    let actionAccessibilityIdentifier: String
    let onSubmit: () -> Void
    let onAction: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        StoreSearchField(
            text: $model.query,
            placeholder: placeholder,
            trailingAction: trailingAction,
            submitLabel: returnKeyType.submitLabel,
            focus: $isFocused,
            accessibilityIdentifier: searchFieldAccessibilityIdentifier
        )
        .onSubmit(onSubmit)
        .onChange(of: model.shouldFocus) { _, shouldFocus in
            isFocused = shouldFocus
        }
        .onChange(of: isFocused) { _, isFocused in
            model.shouldFocus = isFocused
        }
    }

    private var trailingAction: StoreSearchFieldAction? {
        guard hidesAction == false else {
            return nil
        }
        return StoreSearchFieldAction(
            model.actionTitle,
            accessibilityIdentifier: actionAccessibilityIdentifier,
            action: onAction
        )
    }
}

private extension UIReturnKeyType {
    var submitLabel: SubmitLabel {
        switch self {
        case .go:
            .go
        case .join:
            .join
        case .next:
            .next
        case .route:
            .route
        case .search, .google, .yahoo:
            .search
        case .send:
            .send
        case .done:
            .done
        case .continue:
            .continue
        case .default, .emergencyCall:
            .return
        @unknown default:
            .return
        }
    }
}
