# Session service boundaries

Use this reference for changes that connect app coordinators, Yosemite services or actors, and Storage or Networking. This includes POS eligibility.

## Construction and lifetime

Keep UI-facing entry points and protocol requirements on the main actor. Pass only safe `Sendable` values to or from the catalog actor. Use compiler-checked isolation for mutable services.

Construct session services that need the main actor in the main-actor coordinator or factory. Configure the catalog actor before it evaluates eligibility. Check all production construction paths before you change initialization order. Pass dependencies during setup instead of finding them later through a global service locator.

A type-erased Combine publisher does not retain its producer. If a service observes an app-owned state object, retain that object for the service lifetime. Alternatively, use a publisher from an object that the session already retains. Verify lifetime with a weak-reference test.

## Protocol witnesses

An async requirement with a default implementation can hide a missing actor witness. A forwarding extension can accidentally satisfy the requirement if its method has the same name and labels. Default arguments do not make signatures different.

Give a forwarding helper a different label, such as `callerIsolation:`. Forward the call to the required `isolation:` witness. If no default implementation is intended, type-check an incomplete conformer. Confirm that compilation fails. Test calls through the protocol. Confirm that the concrete service receives configuration.

## Async remote calls

Keep cancellation, discovery, and retry unchanged when you call a legacy async remote. Replacing an async Alamofire path with a callback adapter can lose task cancellation.

Where supported, consider an `isolation: isolated (any Actor)? = #isolation` parameter. It can pass caller isolation through the affected Remote and Network API. This avoids declaring a mutable network object `Sendable`. Check how the active compiler handles the async body and each forwarding call. Include retry paths.

## Transitional configuration

Before you add a public eligibility case or error for a missing service, check two facts:

- Does the missing-service branch write to the eligibility cache?
- Does production configure the service before evaluation?

If the branch does not cache its result, it cannot put that result in the later eligibility cache. Confirm that normal evaluation starts after configuration. An unclear diagnostic reason alone does not justify a new public state. Keep session construction safe through compiler-checked isolation. Report remaining diagnostic improvements separately.
