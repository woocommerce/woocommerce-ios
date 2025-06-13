import SwiftUI

/// A property wrapper that provides optional binding functionality for SwiftUI views.
///
/// `OptionalBinding` allows a SwiftUI view to work with either:
/// - An external binding (when provided) - for two-way data synchronization with parent views
/// - Internal state management (when no binding is provided) - for self-contained components
///
/// This is particularly useful for reusable components that need to support both use cases:
/// standalone usage and integration with external state management.
///
/// ## Usage Examples
///
/// ### Basic usage with internal state management:
/// ```swift
/// struct MyView: View {
///     @OptionalBinding private var selectedIndex: Int = 0
///
///     init() {
///         // When no external binding is provided, the component manages its own state
///         self._selectedIndex = OptionalBinding(nil, default: 0)
///     }
/// }
/// ```
///
/// ### Usage with external binding:
/// ```swift
/// struct ParentView: View {
///     @State private var currentIndex = 1
///
///     var body: some View {
///         MyView(selectedIndex: $currentIndex) // Two-way binding
///     }
/// }
///
/// struct MyView: View {
///     @OptionalBinding private var selectedIndex: Int = 0
///
///     init(selectedIndex: Binding<Int>? = nil) {
///         // When external binding is provided, syncs with parent state
///         self._selectedIndex = OptionalBinding(selectedIndex, default: 0)
///     }
/// }
/// ```
///
/// ## Key Features
///
/// - **Automatic fallback**: Uses internal state when no external binding is provided
/// - **Seamless integration**: Works exactly like `@State` or `@Binding` from the view's perspective
/// - **Two-way synchronization**: Changes are automatically propagated to external bindings when present
/// - **Type safety**: Maintains full type safety with generic value types
/// - **SwiftUI compliance**: Conforms to `DynamicProperty` for proper SwiftUI lifecycle integration
///
/// ## Implementation Details
///
/// The property wrapper maintains both an internal `@State` and an optional external `Binding<Value>`.
/// The `wrappedValue` getter/setter automatically routes to the appropriate storage based on whether
/// an external binding was provided during initialization.
///
/// The `projectedValue` returns a `Binding<Value>` that can be passed to child views, maintaining
/// the same behavior regardless of whether the component is using internal or external state.
@propertyWrapper
struct OptionalBinding<Value>: DynamicProperty {
    @State private var internalValue: Value
    private var external: Binding<Value>?

    var wrappedValue: Value {
        get { external?.wrappedValue ?? internalValue }
        nonmutating set {
            if external != nil {
                external?.wrappedValue = newValue
            } else {
                internalValue = newValue
            }
        }
    }

    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }

    init(wrappedValue: Value) {
        self._internalValue = State(initialValue: wrappedValue)
        self.external = nil
    }

    init(_ binding: Binding<Value>?, default defaultValue: Value) {
        if let binding = binding {
            self.external = binding
            self._internalValue = State(initialValue: binding.wrappedValue)
        } else {
            self.external = nil
            self._internalValue = State(initialValue: defaultValue)
        }
    }
}
