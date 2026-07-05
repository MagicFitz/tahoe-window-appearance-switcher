import AppKit
import SwiftUI

enum AppConstants {
    static let displayName = "Tahoe 窗口外观切换器"
    static let fixedWindowSize = CGSize(width: 740, height: 560)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct AppearanceSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = AppearanceStore(
        defaultsService: DefaultsAppearanceService(),
        relaunchService: WorkspaceRelaunchService()
    )

    var body: some Scene {
        WindowGroup(AppConstants.displayName) {
            ContentView(store: store)
                .frame(width: AppConstants.fixedWindowSize.width, height: AppConstants.fixedWindowSize.height)
                .background(WindowConfigurationView(size: AppConstants.fixedWindowSize))
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 \(AppConstants.displayName)") {
                    NSApplication.shared.orderFrontStandardAboutPanel()
                }
            }
        }
    }
}

private struct WindowConfigurationView: NSViewRepresentable {
    let size: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(nsView.window)
        }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }

        window.title = AppConstants.displayName
        window.minSize = size
        window.maxSize = size
        window.setContentSize(size)
        window.styleMask.remove(.resizable)
        window.collectionBehavior.remove(.fullScreenPrimary)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
    }
}
