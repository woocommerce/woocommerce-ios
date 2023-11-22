import Foundation
import Yosemite

public final class MockSystemStatusService: SystemStatusServiceProtocol {
    public init() { }

    public var didCallSynchronizeSystemInformation = false
    public var spySynchronizeSystemInformationSiteID: Int64? = nil
    public var onSynchronizeSystemInformationThenReturn: SystemInformation? = nil
    public var onSynchronizeSystemInformationThenThrow: Error? = nil
    public func synchronizeSystemInformation(siteID: Int64) async throws -> SystemInformation {
        didCallSynchronizeSystemInformation = true
        spySynchronizeSystemInformationSiteID = siteID
        if let shouldThrow = onSynchronizeSystemInformationThenThrow {
            throw shouldThrow
        } else {
            return onSynchronizeSystemInformationThenReturn ?? .fake()
        }
    }

    public var didCallFetchSystemPluginWithPath = false
    public var spyFetchSystemPluginWithPathSiteID: Int64? = nil
    public var onFetchSystemPluginWithPath: ((String) -> SystemPlugin?) = { _ in
        return nil
    }
    public func fetchSystemPluginWithPath(siteID: Int64, pluginPath: String) async -> SystemPlugin? {
        didCallFetchSystemPluginWithPath = true
        spyFetchSystemPluginWithPathSiteID = siteID
        return onFetchSystemPluginWithPath(pluginPath)
    }
}
