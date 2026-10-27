# Session service boundaries

Use this reference for changes that connect app coordinators, Yosemite services or actors, and Storage or Networking. This includes POS eligibility.

## Construction and lifetime

Keep UI-facing entry points and protocol requirements on the main actor. Pass only safe `Sendable` values to or from the catalog actor. Use compiler-checked isolation for mutable services.

Construct session services that need the main actor in the main-actor coordinator or factory. Configure the catalog actor before it evaluates eligibility. Check all production construction paths before you change initialization order. Pass dependencies during setup instead of finding them later through a global service locator.

A type-erased Combine publisher does not retain its producer. If a service observes an app-owned state object, retain that object for the service lifetime. Alternatively, use a publisher from an object that the session already retains. Verify lifetime with a weak-reference test.

## Request handlers for non-Sendable owners

When a `@Sendable` callback captures a non-`Sendable` store, first consider capturing only the required `Sendable` dependencies. Use static helpers for operations that need no instance. Prefer this shape when the request can complete independently of store lifetime.

If callbacks depend on owner lifetime, consider separating dispatcher registration from request handling. Keep the store as the registration object. A private `final` request handler can hold immutable `Sendable` dependencies and implement the request and storage operations. Swift checks its stored properties against their declared sendability. It still relies on any unchecked guarantees in those dependencies. This separation adds no actor, queue, or serialization.

Choose the approach from the existing contract:

- Direct dependency captures use less structure, but can keep requests, writes, and side effects alive after the store is released. Check weak-reference branches before replacing them.
- Whole-store actor isolation fits an actor-owned store only when its dispatcher requirements and callers support that isolation. An actor handler is useful when mutable state needs serialized access; its asynchronous calls can change execution order.
- A checked request handler keeps the non-`Sendable` registration object out of concurrent callbacks without changing the shared store hierarchy. Use it when the lifetime requirement justifies another object. Name it for the work it performs.
- An unchecked conformance on the store needs a separate safety argument for every inherited field and access path. A small checked handler does not require that broader promise.

Verify which object each task and callback retains. The registration object can be released while its handler remains alive. Test release during an in-flight request and release before a queued write. Preserve the intended write, completion, error, retry, and cancellation behavior. Test the negative case by removing the lifetime guard temporarily.

Weak ownership is not session cancellation. Check logout and storage reset separately. A serial write queue does not reject a remote callback that submits a write after reset. Use an explicit cancellation or session-validity contract when work must stop at that boundary.

## Protocol witnesses

An async requirement with a default implementation can hide a missing actor witness. A forwarding extension can accidentally satisfy the requirement if its method has the same name and labels. Default arguments do not make signatures different.

Give a forwarding helper a different label, such as `callerIsolation:`. Forward the call to the required `isolation:` witness. If no default implementation is intended, type-check an incomplete conformer. Confirm that compilation fails. Test calls through the protocol. Confirm that the concrete service receives configuration.

## Async remote calls

Keep cancellation, discovery, and retry unchanged when you call a legacy async remote. Replacing an async Alamofire path with a callback adapter can lose task cancellation.

Where supported, consider an `isolation: isolated (any Actor)? = #isolation` parameter. It can pass caller isolation through the affected Remote and Network API. This avoids declaring a mutable network object `Sendable`. Check how the active compiler handles the async body and each forwarding call. Include retry paths.

This parameter only moves warnings when an actor method calls a service that is not `Sendable`. The service's `self` joins the actor's region. Each onward call to the service, its dependencies, or its private helpers then produces a new `sending` warning. Child tasks that capture the service still warn. In that case, the root cause is the non-`Sendable` service, such as a `Remote` subclass. Fix or report that root cause. `nonisolated(nonsending)` (SE-0461) is another option with Swift 6.2, also in Swift 5 mode. It runs synchronous setup and decoding on the caller's actor. That is an execution change, so verify it.

## Action completions

Add `@Sendable` to Yosemite Action completions one Action case at a time. The compiler checks explicit `@Sendable` closures even under `minimal` checking. Use plain `@Sendable`, not `@MainActor @Sendable`, because the main-actor form makes nonisolated mock stubs fail. A `@Sendable` closure cannot change a captured `var`. Use a lock or async code in those callers.

Treat callback isolation and argument ownership as separate contracts. When an Action completion returns an immutable value model, prefer adding checked `Sendable` conformance to that model and its stored-value graph. Adding `@Sendable` to the callback does not make its arguments transferable, while changing the parameter to `sending` can introduce warnings in stores, mocks, and fixtures that produce actor-isolated values. Reserve `sending` for APIs that genuinely transfer ownership, and compile every producer and caller before adopting it.

## Transitional configuration

Before you add a public eligibility case or error for a missing service, check two facts:

- Does the missing-service branch write to the eligibility cache?
- Does production configure the service before evaluation?

If the branch does not cache its result, it cannot put that result in the later eligibility cache. Confirm that normal evaluation starts after configuration. An unclear diagnostic reason alone does not justify a new public state. Keep session construction safe through compiler-checked isolation. Report remaining diagnostic improvements separately.
