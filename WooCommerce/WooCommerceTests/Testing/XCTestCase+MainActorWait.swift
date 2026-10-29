import XCTest

extension XCTestCase {
    /// Polls `condition` on the main actor, so main actor tests don't hand it to the nonisolated `until` helper.
    @MainActor
    func waitOnMainActor(timeout: Duration = .seconds(5),
                         file: StaticString = #filePath,
                         line: UInt = #line,
                         until condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() && ContinuousClock.now < deadline {
            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                break
            }
        }
        XCTAssertTrue(condition(), file: file, line: line)
    }
}
