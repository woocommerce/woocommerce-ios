import Foundation

/// Temporary canary to exercise the strict-concurrency baseline guard in CI (WOOMOB-3965).
/// The mutable static below deliberately emits exactly one strict-concurrency warning
/// ("static property is not concurrency-safe") in this Swift-5-mode module.
/// DELETE THIS FILE once the guard's failure behavior is verified.
public enum BaselineGuardCanary {
    public static var counter = 0
}
