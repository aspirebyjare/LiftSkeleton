//
//  PoseGeometry.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import Vision

enum PoseGeometry {
    static let bodyConnections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.neck, .root),

        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),

        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),

        (.root, .leftHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),

        (.root, .rightHip),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]
}
