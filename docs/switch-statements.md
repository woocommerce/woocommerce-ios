# Switch Statements Guide

## Enums

When using switch statements to handle enum cases avoid handling `default` case. If we do not provide a default case and in future we add new cases, app will not build and we will immediately see where we have some API changes.

**Preferred:**

```swift
enum EnumExample {
    case first
    case second
    
    func exampleFunction() -> String? {
        switch self {
        case .first:
            return "first example"
        case .second:
            return "second example"
        }
    }
}
```

**Not Preferred:**

```swift
enum EnumExample {
    case first
    case second
    
    func exampleFunction() -> String? {
        switch self {
        case .first:
            return "first example"
        case .second:
            return "second example"
        default:
            return nil
        }
    }
}
```
