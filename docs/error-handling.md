# Error handling

When dealing with functions that may raise errors, we want to handle these gracefully. That means to not let them fail silently, but show the appropiate errors to the user if needed, and/or log these when necessary. 

In order to handle these, we use `do-catch` blocks:

```swift
do {
    let fetchResults = try resultsController.performFetch()
} catch {
    DDLogError("Unable to fetch results controller: \(error)")
}
```
