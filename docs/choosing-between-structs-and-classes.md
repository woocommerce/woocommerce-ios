# Choosing Between Structures and Classes

In addition to the [Apple guidelines](https://developer.apple.com/documentation/swift/choosing_between_structures_and_classes), we generally prefer to use `struct` for:

- Value types like the [Networking Models](../Networking/Networking/Model)
- Stateless helpers

But consider using `class` instead if:

- You need to manage mutable states. Especially if there are more than a few `mutating` functions, the `struct` becomes harder to reason about.
- You have to set a `struct` property declaration as `var` because it has a `mutating` function. In this case, a constant (`let`) `class` property may be easier to reason about.

### Classes should be marked as `Final` by default

When using classes, these should be marked as `final` by default so their behavior cannot be altered by subclassing and/or overriding. There's a few reasons for that:

- It favors composition over inheritance
- The class could be missused or abused when subclassed or overriden, which could be problematic if the class is doing anything important. By making it `final` we disallow this at compiler time, and enforce that the class has to be used as it was written.
- Marking a class as `final` tells the Swift compiler that the class methods should be called directly rather than looking them up in a method table (static vs dynamic dispatch), which [reduces function call overhead and increases performance](https://developer.apple.com/swift/blog/?id=27)
- If inheritance is necessary later on, it can always be allowed, but the `final` modifier will create a reminder of its necessity and refactoring
