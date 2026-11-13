# Localization Rules

Based on `docs/localization.md`. Strings are managed via GlotPress.

## NSLocalizedString Usage
Always use `NSLocalizedString` with three arguments: key, value, and comment.

```swift
// Correct
NSLocalizedString("orders.detail.title", value: "Order Details", comment: "Title for the order detail screen")

// Wrong - using English text as key
NSLocalizedString("Order Details", comment: "Title for the order detail screen")
```

## Key Format
Use unique reverse-DNS naming style: `"feature.screen.element"`

## String Grouping
Group localized strings in a nested `enum Localization` within the class or struct:
```swift
private enum Localization {
    static let title = NSLocalizedString("orders.list.title", value: "Orders", comment: "Navigation bar title")
}
```

## Placeholders
- Always use positional placeholders: `%1$@`, `%2$d` (not `%@`, `%d`)
- Describe each placeholder in the comment
- Use `String(format:)` or `String.localizedStringWithFormat` for formatting

## Prohibited Patterns
- Never use `LocalizedStringKey` (SwiftLint error)
- Never use string interpolation in NSLocalizedString (SwiftLint error)
- Never use variables for key, value, or comment arguments
- Never use triple-quoted strings in NSLocalizedString

## Updating Strings
When changing the value of a localized string, always update the key too. Never change just the value.

## Pluralization
Handle manually with separate singular/plural strings:
```swift
let singular = NSLocalizedString("items.count.singular", value: "%1$d item", comment: "Singular item count")
let plural = NSLocalizedString("items.count.plural", value: "%1$d items", comment: "Plural item count")
let text = count == 1 ? singular : plural
```

## Multiline Strings
Use `+` concatenation for readability. Never use triple-quoted strings.

## Numbers
Localize numbers: `NumberFormatter.localizedString(from: NSNumber(value: count), number: .none)`
