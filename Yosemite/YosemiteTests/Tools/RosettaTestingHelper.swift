import Foundation

private let NATIVE = Int32(0)
private let EMULATED = Int32(1)
private let UNKNOWN = -Int32(1)

/// Based on Apple guidance on how to determine when running under Rosetta.
/// https://developer.apple.com/documentation/apple-silicon/about-the-rosetta-translation-environment
/// Intended for use in tests only.
private func processIsTranslated() -> Int32 {
    var ret = Int32(0)
    var size = ret.bitWidth
    if sysctlbyname("sysctl.proc_translated", &ret, &size, nil, 0) == -1 {
        if errno == ENOENT {
            return NATIVE
        }
        return UNKNOWN
    }
    return ret
}

func testingOnRosetta() -> Bool {
    return processIsTranslated() == EMULATED
}
