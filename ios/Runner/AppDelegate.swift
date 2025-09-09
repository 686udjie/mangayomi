import UIKit
import Flutter
import Libmtorrentserver
import app_links
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let mChannel = FlutterMethodChannel(name: "com.kodjodevf.mangayomi.libmtorrentserver", binaryMessenger: controller.binaryMessenger)
              mChannel.setMethodCallHandler({
                  (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                  switch call.method {
                  case "start":
                      let args = call.arguments as? Dictionary<String, Any>
                      let config = args?["config"] as? String
                      var error: NSError?
                      let mPort = UnsafeMutablePointer<Int>.allocate(capacity: MemoryLayout<Int>.stride)
                      if LibmtorrentserverStart(config, mPort, &error){
                          result(mPort.pointee)
                      }else{
                          result(FlutterError(code: "ERROR", message: error.debugDescription, details: nil))
                      }
                  default:
                      result(FlutterMethodNotImplemented)
                  }
              })

      let mediaChannel = FlutterMethodChannel(name: "com.kodjodevf.mangayomi.media_saver", binaryMessenger: controller.binaryMessenger)
      mediaChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
          switch call.method {
          case "saveImage":
              guard let args = call.arguments as? Dictionary<String, Any>,
                    let data = args["data"] as? FlutterStandardTypedData,
                    let name = args["name"] as? String else {
                  result(FlutterError(code: "ARG_ERROR", message: "Invalid args", details: nil))
                  return
              }
              self.saveImageToPhotos(data: data.data, name: name) { path, error in
                  if let error = error {
                      result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
                  } else {
                      result(path)
                  }
              }
          default:
              result(FlutterMethodNotImplemented)
          }
      })

    GeneratedPluginRegistrant.register(with: self)

    if let url = AppLinks.shared.getLink(launchOptions: launchOptions) {
      AppLinks.shared.handleLink(url: url)
      return true
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveImageToPhotos(data: Data, name: String, completion: @escaping (String?, Error?) -> Void) {
    func performSave() {
      let tmpDir = NSTemporaryDirectory()
      let fileURL = URL(fileURLWithPath: tmpDir).appendingPathComponent(name)
      do {
        try data.write(to: fileURL)
      } catch {
        completion(nil, error)
        return
      }
      PHPhotoLibrary.shared().performChanges({
        let _ = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
      }) { success, error in
        completion(success ? fileURL.path : nil, error)
      }
    }

    let status = PHPhotoLibrary.authorizationStatus()
    if status == .authorized || status == .limited {
      performSave()
    } else if status == .notDetermined {
      PHPhotoLibrary.requestAuthorization { newStatus in
        if newStatus == .authorized || newStatus == .limited {
          performSave()
        } else {
          completion(nil, NSError(domain: "photos", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo access denied"]))
        }
      }
    } else {
      completion(nil, NSError(domain: "photos", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo access denied"]))
    }
  }
}
