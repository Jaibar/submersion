import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var bookmarkHandler: SecurityScopedBookmarkHandler?
  private var icloudHandler: ICloudContainerHandler?
  private var metadataHandler: MetadataWriteHandler?
  private var updateChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    NSLog("[AppDelegate] applicationDidFinishLaunching called")
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      NSLog("[AppDelegate] Got FlutterViewController, setting up handlers...")
      let messenger = controller.engine.binaryMessenger
      bookmarkHandler = SecurityScopedBookmarkHandler(messenger: messenger)
      icloudHandler = ICloudContainerHandler(messenger: messenger)
      metadataHandler = MetadataWriteHandler(messenger: messenger)
      updateChannel = FlutterMethodChannel(
        name: "app.submersion/updates",
        binaryMessenger: messenger
      )
      NSLog("[AppDelegate] All handlers initialized")
    } else {
      NSLog("[AppDelegate] ERROR: Could not get FlutterViewController!")
    }
  }

  @IBAction func checkForUpdates(_ sender: Any) {
    updateChannel?.invokeMethod("checkForUpdateInteractively", arguments: nil)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationWillTerminate(_ notification: Notification) {
    bookmarkHandler?.cleanup()
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
