/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model object that stores state data for the app and acts as a delegate
    for all callbacks during the capture process.
*/

import AVFoundation
import CoreImage
import CoreMotion
import os

private let logger = Logger(subsystem: "com.apple.sample.CaptureSample",
                            category: "PhotoCaptureDelegate")

/// This class stores state and acts as a delegate for all callbacks during the capture process. It pushes the
/// capture objects containing images and metadata back to the specified `CameraViewModel`.
class PhotoCaptureProcessor: NSObject {
    private let photoId: UInt32
    private let model: CameraViewModel

    private(set) var requestedPhotoSettings: AVCapturePhotoSettings

    private let willCapturePhotoAnimation: () -> Void

    lazy var context = CIContext()

    private let completionHandler: (PhotoCaptureProcessor) -> Void

    private let photoProcessingHandler: (Bool) -> Void

    private var maxPhotoProcessingTime: CMTime?

    private let motionManager: CMMotionManager

    private var photoData: AVCapturePhoto?
    private var depthMapData: Data?
    private var depthData: AVDepthData?
    private var gravity: CMAcceleration?

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         model: CameraViewModel,
         photoId: UInt32,
         motionManager: CMMotionManager,
         willCapturePhotoAnimation: @escaping () -> Void,
         completionHandler: @escaping (PhotoCaptureProcessor) -> Void,
         photoProcessingHandler: @escaping (Bool) -> Void) {
        self.photoId = photoId
        self.model = model
        self.motionManager = motionManager
        self.requestedPhotoSettings = requestedPhotoSettings
        self.willCapturePhotoAnimation = willCapturePhotoAnimation
        self.completionHandler = completionHandler
        self.photoProcessingHandler = photoProcessingHandler
    }

    private func didFinish() {
        completionHandler(self)
    }
}

/// This extension adopts all of the `AVCapturePhotoCaptureDelegate` protocol methods.
extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {

    /// - Tag: WillBeginCapture
    func photoOutput(_ output: AVCapturePhotoOutput,
                     willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        maxPhotoProcessingTime = resolvedSettings.photoProcessingTimeRange.start
            + resolvedSettings.photoProcessingTimeRange.duration
    }

    /// - Tag: WillCapturePhoto
    func photoOutput(_ output: AVCapturePhotoOutput,
                     willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        willCapturePhotoAnimation()

        // Retrieve the gravity vector at capture time.
        if motionManager.isDeviceMotionActive {
            gravity = motionManager.deviceMotion?.gravity
            logger.log("Captured gravity vector: \(String(describing: self.gravity))")
        }

        guard let maxPhotoProcessingTime = maxPhotoProcessingTime else {
            return
        }

        // Show a spinner if processing time exceeds one second.
        let oneSecond = CMTime(seconds: 1, preferredTimescale: 1)
        if maxPhotoProcessingTime > oneSecond {
            photoProcessingHandler(true)
        }
    }

    /// - Tag: DidFinishProcessingPhoto
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        photoProcessingHandler(false)

        if let error = error {
            print("Error capturing photo: \(error)")
            photoData = nil
        } else {
            // Cache the HEIF representation of the data.
            photoData = photo
        }

        // Cache the depth data, if it exists, as a disparity map.
        logger.log("DidFinishProcessingPhoto: photo=\(String(describing: photo))")
        if let depthData = photo.depthData?.converting(toDepthDataType:
                                                        kCVPixelFormatType_DisparityFloat32),
           let colorSpace = CGColorSpace(name: CGColorSpace.linearGray) {
            let depthImage = CIImage( cvImageBuffer: depthData.depthDataMap,
                                      options: [ .auxiliaryDisparity: true ] )
            depthMapData = context.tiffRepresentation(of: depthImage,
                                                      format: .Lf,
                                                      colorSpace: colorSpace,
                                                      options: [.disparityImage: depthImage])
        } else {
            logger.error("colorSpace .linearGray not available... can't save depth data!")
            depthMapData = nil
        }
    }

    /// - Tag: DidFinishCapture
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        print("DidFinishCapture!")

        // Call the completion handler when done.
        defer { didFinish() }

        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        guard let photoData = photoData else {
            print("No photo data resource")
            return
        }

        print("Making capture and adding to model...")
        model.addCapture(Capture(id: photoId, photo: photoData, depthData: depthMapData,
                                 gravity: gravity))
    }
}
