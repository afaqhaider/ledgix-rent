import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LedgixOcr") {
      DocumentOcr.register(messenger: registrar.messenger())
    }
  }
}

/// On-device text recognition for document scanning (Apple Vision).
/// Channel "ledgix/ocr", method "recognize" {path} -> [{text, left, top, right, bottom}],
/// coordinates in pixels from the top-left of the (orientation-corrected) image.
enum DocumentOcr {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "ledgix/ocr", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognize",
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let reply: Any
        do {
          reply = try recognize(path: path)
        } catch {
          reply = FlutterError(code: "ocr_failed", message: error.localizedDescription, details: nil)
        }
        DispatchQueue.main.async { result(reply) }
      }
    }
  }

  static func recognize(path: String) throws -> [[String: Any]] {
    guard let image = UIImage(contentsOfFile: path), let cg = image.cgImage else {
      throw NSError(domain: "ledgix.ocr", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unreadable image"])
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    request.recognitionLanguages = ["en-US"]
    let orientation = CGImagePropertyOrientation(image.imageOrientation)
    try VNImageRequestHandler(cgImage: cg, orientation: orientation, options: [:]).perform([request])
    let size = image.size
    return (request.results ?? []).compactMap { obs in
      guard let text = obs.topCandidates(1).first?.string else { return nil }
      let b = obs.boundingBox // normalised, origin bottom-left
      return [
        "text": text,
        "left": Double(b.minX * size.width),
        "top": Double((1 - b.maxY) * size.height),
        "right": Double(b.maxX * size.width),
        "bottom": Double((1 - b.minY) * size.height),
      ]
    }
  }
}

extension CGImagePropertyOrientation {
  init(_ o: UIImage.Orientation) {
    switch o {
    case .up: self = .up
    case .down: self = .down
    case .left: self = .left
    case .right: self = .right
    case .upMirrored: self = .upMirrored
    case .downMirrored: self = .downMirrored
    case .leftMirrored: self = .leftMirrored
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
