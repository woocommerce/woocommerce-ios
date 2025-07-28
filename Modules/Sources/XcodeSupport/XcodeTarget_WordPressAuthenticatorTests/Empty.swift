// We need this file with a dummy type in the package to avoid the following
// error:
//
// > target 'XcodeTarget_<name>' referenced in product 'XcodeTarget_<name>' is empty
import Foundation

public struct __Empty {}
