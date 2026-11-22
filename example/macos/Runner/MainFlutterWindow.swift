import Cocoa
import FlutterMacOS
import macos_window_utils

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    flutterViewController.backgroundColor = .clear
    self.isOpaque = false
    self.contentViewController = MacOSWindowUtilsViewController(flutterViewController: flutterViewController)
    MainFlutterWindowManipulator.start(mainFlutterWindow: self)
    self.backgroundColor = .clear
    self.setFrame(windowFrame, display: true)
    // Default Size
    self.setContentSize(NSSize(width: 640, height: 480))
    // Min Size
    self.contentMinSize = NSSize(width: 640, height: 480)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
