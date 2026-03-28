//
//  CameraManager.swift
//  LiftSkeleton
//
//  Created by Jared Smith on 3/28/26.
//

import AVFoundation
import CoreMedia
import Photos

final class CameraManager: NSObject {
    let session = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    let movieOutput = AVCaptureMovieFileOutput()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoQueue = DispatchQueue(label: "camera.video.queue")

    private var currentVideoInput: AVCaptureDeviceInput?
    private(set) var currentPosition: AVCaptureDevice.Position = .back
    private(set) var isRecording = false

    var onFrame: ((CMSampleBuffer) -> Void)?
    var onRecordingStateChanged: ((Bool) -> Void)?

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

        guard session.canAddOutput(movieOutput) else {
            print("Session cannot add movie output")
            return false
        }

        session.addOutput(movieOutput)

        configureConnections()

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
            if self.isRecording {
                print("Cannot switch camera while recording")
                DispatchQueue.main.async { completion?(false) }
                return
            }

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

                self.configureConnections()

                self.session.commitConfiguration()

                print("Switched camera to: \(self.currentPosition == .front ? "front" : "back")")
                DispatchQueue.main.async { completion?(true) }
            } catch {
                print("Failed to switch camera: \(error)")
                DispatchQueue.main.async { completion?(false) }
            }
        }
    }

    func toggleRecording() {
        sessionQueue.async {
            if self.isRecording {
                self.movieOutput.stopRecording()
            } else {
                let outputURL = self.makeTemporaryRecordingURL()
                self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)

                self.isRecording = true
                DispatchQueue.main.async {
                    self.onRecordingStateChanged?(true)
                }

                print("Started recording to: \(outputURL)")
            }
        }
    }

    private func makeTemporaryRecordingURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "LiftSkeleton-\(UUID().uuidString).mov"
        return tempDir.appendingPathComponent(fileName)
    }

    private func cameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        return discovery.devices.first
    }

    private func configureConnections() {
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }

            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }

        if let connection = movieOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }

    private func saveRecordingToPhotos(from url: URL) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                print("Photo library access not granted")
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if let error {
                    print("Failed to save video to Photos: \(error)")
                } else {
                    print("Saved video to Photos: \(success)")
                }

                try? FileManager.default.removeItem(at: url)
            }
        }
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

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        print("Recording delegate start: \(fileURL)")
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        if let error {
            print("Recording finished with error: \(error)")
        } else {
            print("Recording finished successfully: \(outputFileURL)")
            saveRecordingToPhotos(from: outputFileURL)
        }

        isRecording = false
        DispatchQueue.main.async {
            self.onRecordingStateChanged?(false)
        }
    }
}
