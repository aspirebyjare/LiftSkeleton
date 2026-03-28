//
//  PoseOverlayView.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import UIKit
import Vision
import AVFoundation

final class PoseOverlayView: UIView {

    var observation: VNHumanBodyPoseObservation? {
        didSet { setNeedsDisplay() }
    }

    weak var previewLayer: AVCaptureVideoPreviewLayer?

    var isFrontCamera = false
    var drawJoints = false

    private let confidenceThreshold: Float = 0.2

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard
            let observation,
            let previewLayer,
            let context = UIGraphicsGetCurrentContext()
        else { return }

        context.setLineWidth(3)
        context.setStrokeColor(UIColor.systemGreen.cgColor)
        context.setFillColor(UIColor.systemGreen.cgColor)

        let recognizedPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
        do {
            recognizedPoints = try observation.recognizedPoints(.all)
        } catch {
            return
        }

        for (jointA, jointB) in PoseGeometry.bodyConnections {
            guard
                let pointA = recognizedPoints[jointA], pointA.confidence > confidenceThreshold,
                let pointB = recognizedPoints[jointB], pointB.confidence > confidenceThreshold
            else { continue }

            let a = convertVisionPointToLayer(pointA.location, previewLayer: previewLayer)
            let b = convertVisionPointToLayer(pointB.location, previewLayer: previewLayer)

            context.move(to: a)
            context.addLine(to: b)
            context.strokePath()
        }

        if drawJoints {
            for (_, point) in recognizedPoints where point.confidence > confidenceThreshold {
                let p = convertVisionPointToLayer(point.location, previewLayer: previewLayer)
                let r = CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)
                context.fillEllipse(in: r)
            }
        }
    }

    private func convertVisionPointToLayer(
        _ point: CGPoint,
        previewLayer: AVCaptureVideoPreviewLayer
    ) -> CGPoint {
        let x = isFrontCamera ? (1 - point.x) : point.x
        let flipped = CGPoint(x: x, y: 1 - point.y)
        return previewLayer.layerPointConverted(fromCaptureDevicePoint: flipped)
    }
}
