import Flutter
import UIKit
import ReplayKit
import AVFoundation

// Global variables for crash tracking
private var crashTrackingSessionId: String?
private var crashTrackingPublicKey: String?
private var crashTrackingDefaultHandler: NSUncaughtExceptionHandler?
private let crashEndpoint = "https://api.cuoral.com/customer-intelligence/console-error"
private var isHandlingCrash = false

// Global exception handler
private func globalExceptionHandler(_ exception: NSException) {
    // Prevent duplicate reports if handler is called multiple times
    guard !isHandlingCrash else {
        return
    }
    isHandlingCrash = true
    
    // Send crash report synchronously
    if let sessionId = crashTrackingSessionId, let publicKey = crashTrackingPublicKey {
        sendCrashReportSync(exception: exception, sessionId: sessionId, publicKey: publicKey)
    }
    
    // Call original handler only once
    if let originalHandler = crashTrackingDefaultHandler {
        originalHandler(exception)
    }
}

// Send crash report synchronously with timeout
private func sendCrashReportSync(exception: NSException, sessionId: String, publicKey: String) {
    let deviceInfo: [String: Any] = [
        "device_model": UIDevice.current.model,
        "os_version": UIDevice.current.systemVersion,
        "error_type": "native_crash",
        "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    ]
    
    let crashData: [String: Any] = [
        "message": "\(exception.name.rawValue): \(exception.reason ?? "")",
        "stack_trace": exception.callStackSymbols.joined(separator: "\n"),
        "log_level": "error",
        "url": "native://ios",
        "session_id": sessionId,
        "source": "mobile",
        "console_metadata": deviceInfo
    ]
    
    let array = [crashData]
    
    // Send synchronously with 2 second timeout
    let semaphore = DispatchSemaphore(value: 0)
    
    guard let url = URL(string: crashEndpoint),
          let jsonData = try? JSONSerialization.data(withJSONObject: array) else {
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    request.timeoutInterval = 2.0
    
    let task = URLSession.shared.dataTask(with: request) { _, _, _ in
        semaphore.signal()
    }
    
    task.resume()
    _ = semaphore.wait(timeout: .now() + 2.0)
}

public class CuoralFlutterPlugin: NSObject, FlutterPlugin {
    private var screenRecorder: ScreenRecorder?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cuoral_flutter", binaryMessenger: registrar.messenger())
        let instance = CuoralFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "initializeCrashTracking":
            initializeCrashTracking(call: call, result: result)
            
        case "isRecordingAvailable":
            result(RPScreenRecorder.shared().isAvailable)
            
        case "startRecording":
            startRecording(call: call, result: result)
            
        case "stopRecording":
            stopRecording(result: result)
            
        case "isRecording":
            result(screenRecorder?.isRecording() ?? false)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Crash Tracking
    
    private func initializeCrashTracking(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["sessionId"] as? String,
              let publicKey = args["publicKey"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing sessionId or publicKey", details: nil))
            return
        }
        
        // Set global variables
        crashTrackingSessionId = sessionId
        crashTrackingPublicKey = publicKey
        
        // Save default handler
        crashTrackingDefaultHandler = NSGetUncaughtExceptionHandler()
        
        // Set our custom handler
        NSSetUncaughtExceptionHandler(globalExceptionHandler)
        
        result(true)
    }
    
    // MARK: - Screen Recording
    
    private func startRecording(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        // Check if already recording
        if screenRecorder?.isRecording() == true {
            result(true)
            return
        }
        
        let withAudio = args["withAudio"] as? Bool ?? true
        
        guard RPScreenRecorder.shared().isAvailable else {
            result(FlutterError(code: "NOT_AVAILABLE", message: "Screen recording not available", details: nil))
            return
        }
        
        // Clean up any existing recorder
        screenRecorder = nil
        
        screenRecorder = ScreenRecorder()
        screenRecorder?.startRecording(withAudio: withAudio) { success, error in
            if success {
                result(true)
            } else {
                result(FlutterError(code: "RECORDING_ERROR", message: error ?? "Failed to start recording", details: nil))
            }
        }
    }
    
    private func stopRecording(result: @escaping FlutterResult) {
        guard let recorder = screenRecorder else {
            result(FlutterError(code: "NOT_RECORDING", message: "No active recording", details: nil))
            return
        }
        
        if !recorder.isRecording() {
            self.screenRecorder = nil
            result(FlutterError(code: "NOT_RECORDING", message: "Not currently recording", details: nil))
            return
        }
        
        recorder.stopRecording { filePath, error in
            self.screenRecorder = nil
            
            if let filePath = filePath {
                result(filePath)
            } else {
                result(FlutterError(code: "STOP_ERROR", message: error ?? "Failed to stop recording", details: nil))
            }
        }
    }
}

// MARK: - ScreenRecorder Helper Class

class ScreenRecorder {
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var _isRecording = false
    private var outputURL: URL?
    private var hasReceivedFirstFrame = false
    
    func startRecording(withAudio: Bool, completion: @escaping (Bool, String?) -> Void) {
        // Create output file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let videoDir = documentsPath.appendingPathComponent("cuoral_recordings")
        
        try? FileManager.default.createDirectory(at: videoDir, withIntermediateDirectories: true)
        
        outputURL = videoDir.appendingPathComponent("recording_\(Date().timeIntervalSince1970).mp4")
        
        guard let outputURL = outputURL else {
            completion(false, "Failed to create output file")
            return
        }
        
        // Initialize asset writer
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        } catch {
            completion(false, "Failed to create asset writer: \(error.localizedDescription)")
            return
        }
        
        // Get screen size
        let screenSize = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        let width = Int(screenSize.width * scale)
        let height = Int(screenSize.height * scale)
        
        // Configure video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        
        if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
            assetWriter?.add(videoInput)
        }
        
        // Configure audio input if needed
        if withAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 128000
            ]
            
            audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput?.expectsMediaDataInRealTime = true
            
            if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
                assetWriter?.add(audioInput)
            }
        }
        
        // Start capture
        let recorder = RPScreenRecorder.shared()
        
        recorder.startCapture(handler: { (sampleBuffer, bufferType, error) in
            if let error = error {
                return
            }
            
            guard CMSampleBufferDataIsReady(sampleBuffer) else {
                return
            }
            
            if self.assetWriter?.status == .unknown {
                self.assetWriter?.startWriting()
                self.assetWriter?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
                self.hasReceivedFirstFrame = true
            }
            
            if self.assetWriter?.status == .writing {
                switch bufferType {
                case .video:
                    if let videoInput = self.videoInput, videoInput.isReadyForMoreMediaData {
                        if videoInput.append(sampleBuffer) {
                            self.hasReceivedFirstFrame = true
                        }
                    }
                case .audioApp, .audioMic:
                    if withAudio, let audioInput = self.audioInput, audioInput.isReadyForMoreMediaData {
                        audioInput.append(sampleBuffer)
                    }
                @unknown default:
                    break
                }
            }
        }) { error in
            if let error = error {
                completion(false, "Failed to start capture: \(error.localizedDescription)")
            } else {
                self._isRecording = true
                completion(true, nil)
            }
        }
    }
    
    func stopRecording(completion: @escaping (String?, String?) -> Void) {
        guard _isRecording else {
            completion(nil, "Not recording")
            return
        }
        
        // Set to false first to prevent re-entry
        let wasRecording = _isRecording
        _isRecording = false
        
        guard wasRecording else {
            completion(nil, "Not recording")
            return
        }
        
        // If no frames received, recording never actually started
        if !hasReceivedFirstFrame {
            RPScreenRecorder.shared().stopCapture { _ in
                completion(nil, "No frames captured - check recording permission")
            }
            return
        }
        
        RPScreenRecorder.shared().stopCapture { error in
            
            // Only mark as finished if inputs are ready to avoid crash
            if self.videoInput?.isReadyForMoreMediaData == true {
                self.videoInput?.markAsFinished()
            }
            if self.audioInput?.isReadyForMoreMediaData == true {
                self.audioInput?.markAsFinished()
            }
            
            // Add safety check
            guard let writer = self.assetWriter else {
                completion(nil, "Asset writer is nil")
                return
            }
            
            // Check if writer is in a valid state to finish
            if writer.status != .writing {
                if let outputURL = self.outputURL, FileManager.default.fileExists(atPath: outputURL.path) {
                    completion(outputURL.path, nil)
                } else {
                    let statusName: String
                    switch writer.status {
                    case .unknown: statusName = "unknown"
                    case .writing: statusName = "writing"
                    case .completed: statusName = "completed"
                    case .failed: statusName = "failed"
                    case .cancelled: statusName = "cancelled"
                    @unknown default: statusName = "unknown"
                    }
                    completion(nil, "Asset writer not in writing state: \(statusName)")
                }
                return
            }
            
            writer.finishWriting {
                
                if writer.status == .completed {
                    if let outputURL = self.outputURL {
                        // Add a small delay to ensure file is fully written to disk
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            completion(outputURL.path, nil)
                        }
                    } else {
                        completion(nil, "Output URL is nil")
                    }
                } else if writer.status == .failed {
                    let errorMessage = writer.error?.localizedDescription ?? "Unknown error"
                    completion(nil, "Asset writer failed: \(errorMessage)")
                } else {
                    completion(nil, "Failed to finalize recording")
                }
            }
        }
    }
    
    func isRecording() -> Bool {
        return _isRecording
    }
}

