import Foundation

public extension SystemStatus {
    /// Subtype for details about environment in system status.
    ///
    struct Environment: Decodable {
        let homeURL: String
        let siteURL: String
        let version: String
        let logDirectoryWritable: Bool
        let wpVersion: String
        let wpMultisite: Bool
        let wpMemoryLimit: Int64
        let wpDebugMode: Bool
        let wpCron: Bool
        let language: String
        let externalObjectCache: Bool? // this can return null so keeping it optional
        let serverInfo: String
        let phpVersion: String
        let phpPostMaxSize: Int64
        let phpMaxExecutionTime: Int64
        let phpMaxInputVars: Int64
        let curlVersion: String
        let suhosinInstalled: Bool
        let maxUploadSize: Int64
        let mysqlVersion: String
        let defaultTimezone: String
        let fsockopenOrCurlEnabled: Bool
        let soapClientEnabled: Bool
        let domDocumentEnabled: Bool
        let gzipEnabled: Bool
        let mbstringEnabled: Bool
        let remotePostSuccessful: Bool
        let remoteGetSuccessful: Bool
    }
}

private extension SystemStatus.Environment {
    enum CodingKeys: String, CodingKey {
        case homeURL = "home_url"
        case siteURL = "site_url"
        case version
        case logDirectoryWritable = "log_directory_writable"
        case wpVersion = "wp_version"
        case wpMultisite = "wp_multisite"
        case wpMemoryLimit = "wp_memory_limit"
        case wpDebugMode = "wp_debug_mode"
        case wpCron = "wp_cron"
        case language
        case externalObjectCache = "external_object_cache"
        case serverInfo = "server_info"
        case phpVersion = "php_version"
        case phpPostMaxSize = "php_post_max_size"
        case phpMaxExecutionTime = "php_max_execution_time"
        case phpMaxInputVars = "php_max_input_vars"
        case curlVersion = "curl_version"
        case suhosinInstalled = "suhosin_installed"
        case maxUploadSize = "max_upload_size"
        case mysqlVersion = "mysql_version_string"
        case defaultTimezone = "default_timezone"
        case fsockopenOrCurlEnabled = "fsockopen_or_curl_enabled"
        case soapClientEnabled = "soapclient_enabled"
        case domDocumentEnabled = "domdocument_enabled"
        case gzipEnabled = "gzip_enabled"
        case mbstringEnabled = "mbstring_enabled"
        case remotePostSuccessful = "remote_post_successful"
        case remoteGetSuccessful = "remote_get_successful"
    }
}
