# Coding Style Guide

We use the [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) as the base. We refer to the [raywenderlich.com Swift Style Guide](https://github.com/raywenderlich/swift-style-guide/) for guides that are not described here.

We also use [SwiftLint](https://github.com/realm/SwiftLint) to enforce as many of our rules as we can. 

## Braces

Closing braces should always be placed on a new line regardless of the number of enclosed statements.

**Preferred:**

```swift
guard condition else {
    return
}

if condition {

} else {

}
```

**Not Preferred:**

```swift
guard condition else { return }

if condition { } else { }
```

## Parentheses

Parentheses around conditionals are not required and should be omitted.

**Preferred:**

```swift
if name == "Hello" {
    print("World")
}
```

**Not Preferred:**

```swift
if (name == "Hello") {
    print("World")
}
```

## Forced Downcasts and Unwrapping

Avoid using `as!` to force a downcast, or `!` to force unwrap. Prefer using `as?` to attempt the cast, then deal with the failure case explicitly.

**Preferred:**

```swift
func process(someObject: Any) {
    guard let element = someObject as? Element else {
        // Optional error handling goes here
        return
    }
    process(element)
}
```

**Not Preferred:**

```swift
func process(someObject: Any) {
    process(someObject as! Element)
}
```