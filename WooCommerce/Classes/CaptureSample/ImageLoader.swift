/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Asynchronous image-loading helper class.
*/
import Combine
import CoreGraphics
import CoreImage
import Dispatch
import Foundation
import UIKit

import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "ImageLoader")

/// This helper class asynchronously loads thumbnails and full-size images from a file URL.
class ImageLoader {
    enum Error: Swift.Error {
        case noSuchUrl
        case noThumbnail
        case noImage
        case unknownError(Swift.Error)
    }

    static func loadImage(url: URL) -> Future<UIImage, ImageLoader.Error> {
        let future = Future<UIImage, Error> { promise in
            loaderQueue.async {
                do {
                    logger.debug("Loading image: \(url.path)...")
                    let image = try ImageLoader.loadImageSynchronously(url: url)
                    logger.debug("... done loading thumbnail: \(url.path).")
                    promise(.success(image))
                } catch ImageLoader.Error.noImage {
                    logger.error("noImage \(url.path)")
                    promise(.failure(ImageLoader.Error.noImage))
                } catch ImageLoader.Error.noThumbnail {
                    logger.error("noThumbnail \(url.path)")
                    promise(.failure(ImageLoader.Error.noThumbnail))
                } catch ImageLoader.Error.noSuchUrl {
                    logger.error("noThumbnail \(url.path)")
                    promise(.failure(ImageLoader.Error.noSuchUrl))
                } catch {
                    promise(.failure(ImageLoader.Error.unknownError(error)))
                }
            }
        }
        return future
    }

    static func loadThumbnail(url: URL) -> Future<UIImage, ImageLoader.Error> {
        let future = Future<UIImage, Error> { promise in
            loaderQueue.async {
                do {
                    logger.debug("Loading thumbnail: \(url.path)...")
                    let image = try ImageLoader.loadThumbnailSynchronously(url: url)
                    logger.debug("... done loading thumbnail: \(url.path)...")
                    promise(.success(image))
                } catch ImageLoader.Error.noImage {
                    logger.error("noImage \(url.path)")
                    promise(.failure(ImageLoader.Error.noImage))
                } catch ImageLoader.Error.noThumbnail {
                    logger.error("noThumbnail \(url.path)")
                    promise(.failure(ImageLoader.Error.noThumbnail))
                } catch ImageLoader.Error.noSuchUrl {
                    logger.error("noThumbnail \(url.path)")
                    promise(.failure(ImageLoader.Error.noSuchUrl))
                } catch {
                    logger.error("unknownError \(url.path)")
                    promise(.failure(ImageLoader.Error.unknownError(error)))
                }
            }
        }
        return future
    }

    private static let loaderQueue =
        DispatchQueue(label: "com.apple.example.CaptureSample.AsyncImageLoader",
                      qos: .userInitiated, attributes: .concurrent)

    /// This method synchronously loads the embedded thumbnail. If it can't load the thumbnail, it returns `nil`.
    private static func loadThumbnailSynchronously(url: URL) throws -> UIImage {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            let msg = "Error in CGImageSourceCreateWithURL for \(url.path)"
            logger.error("\(msg)")
            throw Error.noSuchUrl
        }
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, nil) else {
            let msg = "Error in CGImageSourceCreateThumbnailAtIndex for \(url.path)"
            logger.error("\(msg)")
            throw Error.noThumbnail
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }

    /// This method synchronously loads the embedded image. If it can't load the image, it returns `nil`.
    private static func loadImageSynchronously(url: URL) throws -> UIImage {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            let msg = "Error in CGImageSourceCreateWithURL for \(url.path)"
            logger.error("\(msg)")
            throw Error.noSuchUrl
        }
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            let msg = "Error in CGImageSourceCreateImageAtIndex for \(url.path)"
            logger.error("\(msg)")
            throw Error.noImage
        }
        return UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
    }

}
