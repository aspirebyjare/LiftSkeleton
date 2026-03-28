//
//  CameraManager.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import AVFoundation
import CoreMedia

final class CameraManager: NSObject {
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoQueue = DispatchQueue(label: "camera.video.queue")

    private var currentVideoInput: AVCaptureDeviceInput?
    private(set) var currentPosition: AVCaptureDevice.Position = .back

    var onFrame: ((CMSampleBuffer) -> Void)?

    func configureSession(completion: @escaping (Bool) -> Void) {
        sessionQueue.async {
            let success = self.configure()
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    private func configure() -> Bool {
        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        guard let device = cameraDevice(for: currentPosition) else {
            print("Failed to get camera device")
            return false
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

            guard session.canAddInput(input) else {
                print("Session cannot add input")
                return false
            }

            session.addInput(input)
            currentVideoInput = input
        } catch {
            print("Failed to create camera input: \(error)")
            return false
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        guard session.canAddOutput(videoOutput) else {
            print("Session cannot add video output")
            return false
        }

        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }

        print("Camera session configured successfully")
        return true
    }

    func startRunning() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
            print("Camera session started: \(self.session.isRunning)")
        }
    }

    func stopRunning() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
            print("Camera session stopped")
        }
    }

    func switchCamera(completion: ((Bool) -> Void)? = nil) {
        sessionQueue.async {
            let newPosition: AVCaptureDevice.Position = (self.currentPosition == .back) ? .front : .back

            guard let newDevice = self.cameraDevice(for: newPosition) else {
                print("Failed to get new camera device")
                DispatchQueue.main.async { completion?(false) }
                return
            }

            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)

                self.session.beginConfiguration()

                if let currentInput = self.currentVideoInput {
                    self.session.removeInput(currentInput)
                }

                guard self.session.canAddInput(newInput) else {
                    print("Session cannot add new input")
                    self.session.commitConfiguration()
                    DispatchQueue.main.async { completion?(false) }
                    return
                }

                self.session.addInput(newInput)
                self.currentVideoInput = newInput
                self.currentPosition = newPosition

                if let connection = self.videoOutput.connection(with: .video),
                   connection.isVideoRotationAngleSupported(90) {
                    connection.videoRotationAngle = 90
                }

                self.session.commitConfiguration()

                print("Switched camera to: \(self.currentPosition == .front ? "front" : "back")")
                DispatchQueue.main.async { completion?(true) }
            } catch {
                print("Failed to switch camera: \(error)")
                DispatchQueue.main.async { completion?(false) }
            }
        }
    }

    private func cameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        return discovery.devices.first
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onFrame?(sampleBuffer)
    }
}

//import AVFoundation
//import CoreMedia
//
//final class CameraManager: NSObject {
//    let session = AVCaptureSession()
//    let videoOutput = AVCaptureVideoDataOutput()
//
//    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
//    private let videoQueue = DispatchQueue(label: "camera.video.queue")
//
//    var onFrame: ((CMSampleBuffer) -> Void)?
//
//    func configureSession(completion: @escaping (Bool) -> Void) {
//        sessionQueue.async {
//            let success = self.configure()
//            DispatchQueue.main.async {
//                completion(success)
//            }
//        }
//    }
//
//    private func configure() -> Bool {
//        session.beginConfiguration()
//        session.sessionPreset = .high
//
//        defer {
//            session.commitConfiguration()
//        }
//
//        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
//            print("Failed to get camera device")
//            return false
//        }
//
//        do {
//            let input = try AVCaptureDeviceInput(device: device)
//
//            guard session.canAddInput(input) else {
//                print("Session cannot add input")
//                return false
//            }
//
//            session.addInput(input)
//        } catch {
//            print("Failed to create camera input: \(error)")
//            return false
//        }
//
//        videoOutput.alwaysDiscardsLateVideoFrames = true
//        videoOutput.videoSettings = [
//            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//        ]
//        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
//
//        guard session.canAddOutput(videoOutput) else {
//            print("Session cannot add video output")
//            return false
//        }
//
//        session.addOutput(videoOutput)
//
//        if let connection = videoOutput.connection(with: .video) {
//            if connection.isVideoRotationAngleSupported(90) {
//                connection.videoRotationAngle = 90
//            } else {
//                print("Video rotation angle 90 not supported")
//            }
//        } else {
//            print("No video connection found")
//        }
//
//        print("Camera session configured successfully")
//        return true
//    }
//
//    func startRunning() {
//        sessionQueue.async {
//            guard !self.session.isRunning else { return }
//            self.session.startRunning()
//            print("Camera session started: \(self.session.isRunning)")
//        }
//    }
//
//    func stopRunning() {
//        sessionQueue.async {
//            guard self.session.isRunning else { return }
//            self.session.stopRunning()
//            print("Camera session stopped")
//        }
//    }
//}
//
//extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(
//        _ output: AVCaptureOutput,
//        didOutput sampleBuffer: CMSampleBuffer,
//        from connection: AVCaptureConnection
//    ) {
//        onFrame?(sampleBuffer)
//    }
//}
