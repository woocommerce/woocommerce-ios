# Coding Style Guide

We use the [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) as the base. We refer to the [raywenderlich.com Swift Style Guide](https://github.com/raywenderlich/swift-style-guide/) for guides that are not described here.

We also use [SwiftLint](https://github.com/realm/SwiftLint) to enforce as many of our rules as we can. 

## Braces

Closing braces should always be placed on a new line regardless of the number of enclosed statements.

#### Preferred

```swift
guard condition else {
   return
}

if condition {

} else  {

}
```

#### Not Preferred

```swift
guard condition else { return }

if condition { } else { }
```