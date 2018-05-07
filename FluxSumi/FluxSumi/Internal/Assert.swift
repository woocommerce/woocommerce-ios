import Foundation


/// Internal helper to enforce Main Thread execution.
///
func assertMainThread(file: StaticString = #file, line: UInt = #line) {
    assert(Thread.current.isMainThread, "Dispatcher should only be called from the main thread", file: file, line: line)
}
