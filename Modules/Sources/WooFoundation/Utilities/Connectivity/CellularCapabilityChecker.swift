import Darwin

public struct CellularCapabilityChecker {
    public static func deviceHasCellularCapability() -> Bool {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrs) == 0 else { return false }
        defer { freeifaddrs(addrs) }

        var cursor = addrs
        while let addr = cursor {
            guard let namePtr = addr.pointee.ifa_name else {
                cursor = addr.pointee.ifa_next
                continue
            }

            let name = String(cString: namePtr)
            // This isn't a great check, but the alternatives are deprecated, and apparently it's commonly used.
            // pdp_ip0 is the first cellular interface – it's not present if there's no cellular hardware.
            if name == "pdp_ip0" {
                return true
            }
            cursor = addr.pointee.ifa_next
        }
        return false
    }
}
