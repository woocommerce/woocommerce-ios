import UIKit

/// A specialized image cache that performs image decoding off the main thread
/// and stores fully decoded images in memory for optimal scrolling performance.
///
/// This cache is designed as a micro-optimization for image-heavy views such as
/// product catalogs, image galleries, and carousels.
///
/// Key characteristics:
/// - Uses NSCache for automatic memory management and eviction.
/// - Forces image decoding in a background queue.
/// - Returns ready-to-display UIImage instances on the main thread.
/// - Provides profiling hooks via PerformanceLogger.
final class OptimizedImageCache {
    
    // MARK: - Singleton
    static let shared = OptimizedImageCache()
    
    // MARK: - Types
    
    /// Represents a cache key for images.
    struct CacheKey: Hashable {
        let url: URL?
        let identifier: String?
        
        init(url: URL? = nil, identifier: String? = nil) {
            self.url = url
            self.identifier = identifier
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(url?.absoluteString)
            hasher.combine(identifier)
        }
        
        static func == (lhs: CacheKey, rhs: CacheKey) -> Bool {
            return lhs.url == rhs.url && lhs.identifier == rhs.identifier
        }
        
        var debugDescription: String {
            if let url = url {
                return "URL(\(url.absoluteString))"
            } else if let identifier = identifier {
                return "ID(\(identifier))"
            } else {
                return "Unknown"
            }
        }
    }
    
    /// Represents a request token that can be used to cancel in-flight decoding.
    final class RequestToken {
        fileprivate var isCancelled = false
        
        func cancel() {
            isCancelled = true
        }
    }
    
    // MARK: - Properties
    
    private let cache = NSCache<WrappedCacheKey, UIImage>()
    private let decodeQueue: DispatchQueue
    private let lock = NSLock()
    
    /// The maximum number of concurrent decode operations.
    private let maxConcurrentDecodes: Int = 4
    private var currentDecodes: Int = 0
    
    // MARK: - Initialization
    
    private init() {
        cache.countLimit = 512               // Tunable based on memory constraints
        cache.totalCostLimit = 200 * 1024 * 1024  // ~200 MB
        
        decodeQueue = DispatchQueue(
            label: "com.automattic.woocommerce.optimizedImageDecodeQueue",
            qos: .userInitiated,
            attributes: .concurrent
        )
    }
    
    // MARK: - Public API
    
    /// Retrieves an image for the given key, decoding it off the main thread if needed.
    ///
    /// - Parameters:
    ///   - key: The cache key identifying the image.
    ///   - sourceProvider: A closure that returns the image data (e.g., from disk or network).
    ///   - completion: Called on the main thread with the decoded image or nil.
    /// - Returns: A RequestToken that can be used to cancel the request.
    @discardableResult
    func image(
        for key: CacheKey,
        sourceProvider: @escaping () -> Data?,
        completion: @escaping (UIImage?) -> Void
    ) -> RequestToken {
        let token = RequestToken()
        let wrappedKey = WrappedCacheKey(key)
        
        // 1. Fast path: look up in cache
        if let cachedImage = cache.object(forKey: wrappedKey) {
            PerformanceLogger.shared.event(.imageCacheHit)
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return token
        }
        
        PerformanceLogger.shared.event(.imageCacheMiss)
        
        // 2. Background decode path
        decodeQueue.async { [weak self] in
            guard let self = self, !token.isCancelled else { return }
            
            self.lock.lock()
            if self.currentDecodes >= self.maxConcurrentDecodes {
                self.lock.unlock()
                // Throttle by sleeping a tiny amount if overloaded.
                // This keeps memory and CPU usage under control.
                Thread.sleep(forTimeInterval: 0.005)
                _ = self.image(for: key, sourceProvider: sourceProvider, completion: completion)
                return
            }
            self.currentDecodes += 1
            self.lock.unlock()
            
            let signpostID = PerformanceLogger.shared.makeSignpostID()
            PerformanceLogger.shared.begin(.imageDecode, id: signpostID)
            
            defer {
                self.lock.lock()
                self.currentDecodes -= 1
                self.lock.unlock()
                
                PerformanceLogger.shared.end(.imageDecode, id: signpostID)
            }
            
            guard !token.isCancelled else { return }
            guard let data = sourceProvider() else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let decodedImage = self.decodeImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self.cache.setObject(decodedImage, forKey: wrappedKey, cost: decodedImage.memoryCost)
            
            guard !token.isCancelled else { return }
            DispatchQueue.main.async {
                completion(decodedImage)
            }
        }
        
        return token
    }
    
    /// Clears the entire image cache.
    func clear() {
        cache.removeAllObjects()
    }
    
    /// Removes the image for a specific key.
    func removeImage(for key: CacheKey) {
        cache.removeObject(forKey: WrappedCacheKey(key))
    }
    
    // MARK: - Private Helpers
    
    private func decodeImage(data: Data) -> UIImage? {
        guard let image = UIImage(data: data, scale: UIScreen.main.scale) else {
            return nil
        }
        
        return forceDecodeImage(image)
    }
    
    /// Forces decode of the given image by drawing it into a bitmap context.
    ///
    /// - Parameter image: The UIImage to decode.
    /// - Returns: A new UIImage instance that is fully decoded and ready for display.
    private func forceDecodeImage(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bytesPerPixel = 4
        let bytesPerRow = Int(size.width) * bytesPerPixel
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }
        
        let rect = CGRect(origin: .zero, size: size)
        context.draw(cgImage, in: rect)
        
        guard let decodedCGImage = context.makeImage() else {
            return image
        }
        
        let decodedImage = UIImage(
            cgImage: decodedCGImage,
            scale: image.scale,
            orientation: image.imageOrientation
        )
        return decodedImage
    }
}

// MARK: - UIImage Helpers

private extension UIImage {
    /// Rough estimate of the image's memory cost in bytes.
    var memoryCost: Int {
        guard let cgImage = self.cgImage else { return 0 }
        let bytesPerPixel = 4
        return cgImage.width * cgImage.height * bytesPerPixel
    }
}

// MARK: - NSCache Key Wrapper

private final class WrappedCacheKey: NSObject {
    let key: OptimizedImageCache.CacheKey
    
    init(_ key: OptimizedImageCache.CacheKey) {
        self.key = key
    }
    
    override var hash: Int {
        return key.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WrappedCacheKey else {
            return false
        }
        return key == other.key
    }
}

