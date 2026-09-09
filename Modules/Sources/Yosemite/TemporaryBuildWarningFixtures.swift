// Temporary CI fixtures for the build warning guard. Do not merge.
#warning("[TEMP] Explicit compiler warning for the build warning guard smoke test")
#warning("[TEMP] Literal formatting: `code` | [link](https://example.invalid) </details> & @warning-guard-fixture")

private enum TemporaryBuildWarningFixtures {
    static func emitWarnings() {
        let temporaryUnusedValue = 1
        var temporaryNeverMutatedValue = 2
        _ = temporaryNeverMutatedValue
        deprecatedWarningFixture()
    }

    @available(*, deprecated, message: "[TEMP] Deprecated call for the build warning guard smoke test")
    private static func deprecatedWarningFixture() {}
}
