//
//  PoseDetector.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import Vision
import CoreMedia
import ImageIO

final class PoseDetector {
    private let request = VNDetectHumanBodyPoseRequest()

    func detectPose(
        in sampleBuffer: CMSampleBuffer,
        orientation: CGImagePropertyOrientation = .right
    ) -> VNHumanBodyPoseObservation? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )

        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            print("Pose detection failed: \(error)")
            return nil
        }
    }
}
