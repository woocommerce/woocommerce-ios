import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BehaviorSubjectTests.allTests),
        testCase(PublishSubjectTests.allTests),
    ]
}
#endif
