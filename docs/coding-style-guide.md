# Coding Style Guide

We use the [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) as the base. We refer to the [raywenderlich.com Swift Style Guide](https://github.com/raywenderlich/swift-style-guide/) for guides that are not described here.

## SwiftLint

We use [SwiftLint](https://github.com/realm/SwiftLint) to enforce as many of our rules as we can. It is integrated in the build process so you should see any violations in Xcode.

You can the lint check manually by executing `bundle exec rake lint` in the command line. You can also run `bundle exec rake lint:autocorrect` to automatically fix any lint issues.

The SwiftLint rules are automatically enforced by [Hound](https://houndci.com) when pull requests are submitted.

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

**As an exception to this rule,** guarding for a safe `self` is allowed to be expressed in one line.
```swift
guard let self = self else { return }
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

## Error Handling

Avoid using `try?` when a function may throw an error, as it would fail silently. We can use a `do-catch` block instead to handle and log the error as needed. 

**Preferred:**

```swift
do {
    let fetchResults = try resultsController.performFetch()
} catch {
    DDLogError("Unable to fetch results controller: \(error)")
}
```

**Not Preferred:**

```swift
let fetchResults = try? resultsController.performFetch()
```

### Reporting handled errors (crash logging)

`DDLogError` only writes to the local console — it is **not** reported anywhere. When an error matters in production (it signals a real problem rather than an expected/recoverable condition), also report it to the crash-logging system so it surfaces in Sentry as a handled, non-crash event while the app keeps running:

```swift
// An Error worth surfacing in production:
ServiceLocator.crashLogging.logError(error, userInfo: ["context": "receipt upload"], level: .error)

// A non-Error condition worth flagging:
ServiceLocator.crashLogging.logMessage("Payment intent had no id", properties: nil, level: .warning)
```

`SeverityLevel` is `.fatal / .error / .warning / .info / .debug`. Never silently swallow an error: report a handled event for recoverable problems, and fail fast (crash) when the state is genuinely unrecoverable or corrupted — see below.

| Goal | Use |
|------|-----|
| Local-only console log (development) | `DDLogError` / `DDLogWarn` / … |
| Report to Sentry, keep running | `crashLogging.logError(_:userInfo:level:)` / `logMessage(_:properties:level:)` |
| Report to Sentry, then terminate | `crashLogging.logFatalErrorAndExit(_:userInfo:)` |

### Crashing with `fatalError`

Every `fatalError` (and `preconditionFailure` / `assertionFailure`) must be preceded by a comment justifying **why crashing is the correct response** and why the state is genuinely unrecoverable. If the app can keep running, report the error via `crashLogging.logError` / `logMessage` instead of crashing.

```swift
// fatalError: the app cannot function without a valid managed object model. This only
// happens on a corrupt or incompatible install, which cannot be recovered at runtime.
fatalError("Could not load the Core Data model")
```

When you must both report *and* terminate on a truly unrecoverable state, prefer `crashLogging.logFatalErrorAndExit(_:userInfo:)` (today used only by `CoreDataManager` for launch-time Core Data failures) over a bare `fatalError`, so the incident reaches Sentry with its metadata before the process exits.
