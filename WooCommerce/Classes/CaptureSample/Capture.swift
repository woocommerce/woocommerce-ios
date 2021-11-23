/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model for captured images and their associated metadata.
*/
import AVFoundation
import Combine
import CoreGraphics
import CoreImage
import CoreMotion
import Foundation
import UIKit
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "Capture")

/// This is a data object that contains one image and its associated metadata, including gravity, depth,
/// and alpha mask.
struct Capture: Identifiable {
    /// This is the unique ID for this capture.
    let id: UInt32

    /// This is the original photo object, including preview.
    let photo: AVCapturePhoto

    /// This property returns the image preview. It returns a cached preview if one is available. If there's no
    /// cached preview, it creates a preview image, caches it, then returns it.
    var previewUiImage: UIImage? {
        makePreview()
    }

    /// This property holds the depth data in TIFF format.
    var depthData: Data? = nil

    /// This is the phone's gravity vector at the moment the phone captured the image.
    var gravity: CMAcceleration? = nil

    /// This view displays the full-size image.
    var uiImage: UIImage {
        return UIImage(data: photo.fileDataRepresentation()!, scale: 1.0)!
    }

    init(id: UInt32, photo: AVCapturePhoto, depthData: Data? = nil,
         gravity: CMAcceleration? = nil) {
        self.id = id
        self.photo = photo
        self.depthData = depthData
        self.gravity = gravity
    }

    /// This method writes the captured images to a specified folder. This method saves the image as
    /// `IMG_<ID>.HEIC`, the depth data, if available, as `IMG_<ID>_depth.TIF`, and the gravity
    /// vector, if available, as `IMG_<ID>_gravity.TXT`.
    func writeAllFiles(to captureDir: URL) throws {
        writeImage(to: captureDir)
        writeGravityIfAvailable(to: captureDir)
        writeDepthIfAvailable(to: captureDir)
    }

    // MARK: - Private Helpers

    private var photoIdString: String {
        return CaptureInfo.photoIdString(for: id)
    }

    private func makePreview() -> UIImage? {
        if let previewPixelBuffer = photo.previewPixelBuffer {
            let ciImage: CIImage = CIImage(cvPixelBuffer: previewPixelBuffer)
            let context: CIContext = CIContext(options: nil)
            let cgImage: CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
            return UIImage(cgImage: cgImage, scale: 1.0,
                           orientation: uiImage.imageOrientation)
        } else {
            return nil
        }
    }

    @discardableResult
    private func writeImage(to captureDir: URL) -> Bool {
        let imageUrl = CaptureInfo.imageUrl(in: captureDir, id: id)
        print("Saving: \(imageUrl.path)...")
        logger.log("Depth Data = \(String(describing: photo.depthData))")
        do {
            try photo.fileDataRepresentation()!
                .write(to: URL(fileURLWithPath: imageUrl.path), options: .atomic)
            return true
        } catch {
            logger.error("Can't write image to \"\(imageUrl.path)\" error=\(String(describing: error))")
            return false
        }
    }

    @discardableResult
    private func writeGravityIfAvailable(to captureDir: URL) -> Bool {
        guard let gravityVector = gravity else {
            return false
        }
        let gravityString =
            String(format: "%lf,%lf,%lf", gravityVector.x, gravityVector.y, gravityVector.z)
        let gravityUrl = CaptureInfo.gravityUrl(in: captureDir, id: id)
        logger.log("Writing gravity metadata to: \"\(gravityUrl.path)\"...")
        do {
            try gravityString.write(toFile: gravityUrl.path, atomically: true,
                                    encoding: .utf8)
            logger.log("... done.")
            return true
        } catch {
            logger.error(
                "can't write \(gravityUrl.path) error=\(String(describing: error))")
            return false
        }
    }

    @discardableResult
    private func writeDepthIfAvailable(to captureDir: URL) -> Bool {
        guard let depthMapData = depthData else {
            logger.warning("No depth data to save!")
            return false
        }

        let depthMapUrl = CaptureInfo.depthUrl(in: captureDir, id: id)
        logger.log("Writing depth data to path=\"\(depthMapUrl.path)\"...")
        do {
            try depthMapData.write(to: URL(fileURLWithPath: depthMapUrl.path), options: .atomic)
            return true
        } catch {
            logger.error("Can't write depth tiff to: \"\(depthMapUrl.path)\" error=\(String(describing: error))")
            return false
        }
    }
}
