import ScreenObject

// These are implemented as extensions on `ScreenObject` locally to this target to allow us to
// finish the transition of the screens from `BaseScreen` to `ScreenObject` and from the different
// test targets to the share UI tests foundation one. Once that's done, we'll likely want to move
// these in the package itself.
public extension ScreenObject {

    // Pops the navigation stack, returning to the item above the current one
    func pop() {
        navBackButton.tap()
    }

    func then(_ completion: () -> Void) -> Self {
        completion()
        return self
    }

    /// This would be way nicer if we could base `Self` as the type of `completion` parameter.
    func then(_ completion: (ScreenObject) -> Void) -> Self {
        completion(self)
        return self
    }
}
