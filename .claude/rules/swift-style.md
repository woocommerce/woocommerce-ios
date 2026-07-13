# Swift Style Rules

These rules are enforced by SwiftLint (see `.swiftlint.yml` for the full configuration). Based on [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with project-specific additions from `docs/coding-style-guide.md`.

## Braces
- Closing braces on a new line, never single-line blocks
- Exception: `guard let self = self else { return }` is allowed on one line

## Parentheses
- No parentheses around conditionals in if/guard/while/for (SwiftLint error)

## Optionals and Casting
- Never use `as!` or force unwrap with `!`. Use `as?` with guard/if-let
- Avoid `try?` for silent failure. Use `do-catch` and log errors with `DDLogError`

## Error Handling and Crash Logging
- `DDLog*` writes to the local console only — it is NOT reported to Sentry
- Report production-relevant errors to the crash-logging system: `ServiceLocator.crashLogging.logError(_:userInfo:level:)` or `logMessage(_:properties:level:)` (`SeverityLevel` = `.fatal/.error/.warning/.info/.debug`)
- Fail fast: crash (`fatalError`) when the app reaches a genuinely unrecoverable or corrupted state. For recoverable errors, report a handled event (`logError`/`logMessage`) rather than silently swallowing it — never swallow
- Every `fatalError` / `preconditionFailure` / `assertionFailure` MUST have a preceding comment justifying why crashing is correct and the state is unrecoverable
- To report AND terminate on a truly unrecoverable state, use `crashLogging.logFatalErrorAndExit(_:userInfo:)` rather than a bare `fatalError` — it delivers the event to Sentry with metadata before exit
- See `docs/coding-style-guide.md` (Error Handling) for examples

## Access Control
- Use the most restrictive access level possible
- Mark classes `final` unless designed for subclassing
- Prefer `private` over `fileprivate`
- Prefer immutable properties for external access — use `private(set)` for properties that need to be mutable internally but read-only externally, and `let` over `var` whenever possible

## Naming
- Protocols for a single type: append `Protocol` (e.g., `ProductsRemoteProtocol`)
- Capability protocols: use `-able`, `-ible`, `-ing` suffixes
- Group localized string constants in nested `enum Localization { }`

## RTL and Alignment
- Never use `.left` or `.right` for `contentHorizontalAlignment` — use `naturalContentHorizontalAlignment`
- Prefer `.natural` over `.left` for `textAlignment`
- When `.right` is needed for textAlignment, handle RTL and suppress SwiftLint warning

## Imports
- No duplicate imports
- Use targeted imports when importing a single protocol: `import protocol WooFoundation.Analytics`

## Line Length
- Maximum 163 characters (SwiftLint enforced)

## Vertical Whitespace
- Maximum 3 consecutive empty lines (SwiftLint error)

## MARK Comments
- Use valid `// MARK: -` format

## Files
- Must end with a single trailing newline
- No trailing whitespace on any line
- No trailing semicolons
