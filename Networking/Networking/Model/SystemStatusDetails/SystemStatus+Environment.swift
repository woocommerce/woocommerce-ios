import Foundation

public extension SystemStatus {
    /// Subtype for details about environment in system status.
    ///
    struct Environment: Decodable {
        public let homeURL: String
        public let siteURL: String
        public let version: String
        public let logDirectoryWritable: Bool
        public let wpVersion: String
        public let wpMultisite: Bool
        public let wpMemoryLimit: Int64
        public let wpDebugMode: Bool
        public let wpCron: Bool
        public let language: String
        public let externalObjectCache: Bool? // this can return null so keeping it optional
        public let serverInfo: String
        public let phpVersion: String
        public let phpPostMaxSize: Int64
        public let phpMaxExecutionTime: Int64
        public let phpMaxInputVars: Int64
        public let curlVersion: String
        public let suhosinInstalled: Bool
        public let maxUploadSize: Int64
        public let mysqlVersion: String
        public let defaultTimezone: String
        public let fsockopenOrCurlEnabled: Bool
        public let soapClientEnabled: Bool
        public let domDocumentEnabled: Bool
        public let gzipEnabled: Bool
        public let mbstringEnabled: Bool
        public let remotePostSuccessful: Bool
        public let remoteGetSuccessful: Bool
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
