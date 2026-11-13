// This file bridges logging commands from the current module to our logging
// library. You can call any DDLog… function from any Swift file in this module
// without having to import CocoaLumberjackSwift manually.
//
// This file should be copied into or included in any module where we want to
// provide this functionality.
//
// The overhead of this indirection should be zero because the compiler
// should inline all calls. (We could annotate the functions with
// `@inline(__always)` to enfore inlining, but that attribute is not officially
// supported as of Swift 4.0.)

import CocoaLumberjackSwift

/// The logging level threshold for DDLog… calls from Swift.
/// Change this to adjust the verbosity of the log.
///
/// Mirrors the default of `CocoaLumberjackSwift.dynamicLogLevel`, a nonisolated global `var`
/// that Swift 6 cannot read here. The app sets `.verbose` at launch, which passes the same messages.
///
/// Example:
///     internal let defaultDebugLevel: DDLogLevel = .verbose
internal let defaultDebugLevel: DDLogLevel = .all

internal func DDLogDebug(_ message: @autoclosure () -> String,
                         level: DDLogLevel = defaultDebugLevel,
                         context: Int = 0,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         tag: Any? = nil,
                         asynchronous async: Bool = true,
                         ddlog: DDLog = DDLog.sharedInstance) {
    CocoaLumberjackSwift.DDLogDebug("\(message())",
                              level: level,
                              context: context,
                              file: file,
                              function: function,
                              line: line,
                              tag: tag,
                              asynchronous: async,
                              ddlog: ddlog)
}

internal func DDLogInfo(_ message: @autoclosure () -> String,
                        level: DDLogLevel = defaultDebugLevel,
                        context: Int = 0,
                        file: StaticString = #file,
                        function: StaticString = #function,
                        line: UInt = #line,
                        tag: Any? = nil,
                        asynchronous async: Bool = true,
                        ddlog: DDLog = DDLog.sharedInstance) {
    CocoaLumberjackSwift.DDLogInfo("\(message())",
                              level: level,
                              context: context,
                              file: file,
                              function: function,
                              line: line,
                              tag: tag,
                              asynchronous: async,
                              ddlog: ddlog)
}

internal func DDLogWarn(_ message: @autoclosure () -> String,
                        level: DDLogLevel = defaultDebugLevel,
                        context: Int = 0,
                        file: StaticString = #file,
                        function: StaticString = #function,
                        line: UInt = #line,
                        tag: Any? = nil,
                        asynchronous async: Bool = true,
                        ddlog: DDLog = DDLog.sharedInstance) {
    CocoaLumberjackSwift.DDLogWarn("\(message())",
                              level: level,
                              context: context,
                              file: file,
                              function: function,
                              line: line,
                              tag: tag,
                              asynchronous: async,
                              ddlog: ddlog)
}

internal func DDLogVerbose(_ message: @autoclosure () -> String,
                           level: DDLogLevel = defaultDebugLevel,
                           context: Int = 0,
                           file: StaticString = #file,
                           function: StaticString = #function,
                           line: UInt = #line,
                           tag: Any? = nil,
                           asynchronous async: Bool = true,
                           ddlog: DDLog = DDLog.sharedInstance) {
    CocoaLumberjackSwift.DDLogVerbose("\(message())",
                                 level: level,
                                 context: context,
                                 file: file,
                                 function: function,
                                 line: line,
                                 tag: tag,
                                 asynchronous: async,
                                 ddlog: ddlog)
}

internal func DDLogError(_ message: @autoclosure () -> String,
                         level: DDLogLevel = defaultDebugLevel,
                         context: Int = 0,
                         file: StaticString = #file,
                         function: StaticString = #function,
                         line: UInt = #line,
                         tag: Any? = nil,
                         asynchronous async: Bool = false,
                         ddlog: DDLog = DDLog.sharedInstance) {
    CocoaLumberjackSwift.DDLogError("\(message())",
                               level: level,
                               context: context,
                               file: file,
                               function: function,
                               line: line,
                               tag: tag,
                               asynchronous: async,
                               ddlog: ddlog)
}
