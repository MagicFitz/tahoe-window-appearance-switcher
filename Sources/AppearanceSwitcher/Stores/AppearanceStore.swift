import Foundation

@MainActor
final class AppearanceStore: ObservableObject {
    @Published private(set) var snapshot = AppearanceSnapshot(
        windowCornerRadius: nil,
        sidebarCornerRadius: nil,
        floatingSidebar: nil
    )
    @Published var selectedMode: AppearanceMode = .rounded
    @Published private(set) var isApplying = false
    @Published var statusMessage = "读取当前系统外观设置中..."
    @Published var errorMessage: String?

    private let defaultsService: AppearanceDefaultsServicing
    private let relaunchService: AppRelaunchServicing

    init(defaultsService: AppearanceDefaultsServicing, relaunchService: AppRelaunchServicing) {
        self.defaultsService = defaultsService
        self.relaunchService = relaunchService
        refresh()
    }

    var currentMode: AppearanceMode {
        snapshot.mode
    }

    var hasPendingChange: Bool {
        selectedMode != .custom && selectedMode != currentMode
    }

    func refresh() {
        do {
            snapshot = try defaultsService.readSnapshot()
            selectedMode = snapshot.mode == .custom ? .classic : snapshot.mode
            statusMessage = snapshot.mode == .custom ? "当前为自定义外观，可切换到圆润或经典预设。" : "当前为\(snapshot.mode.title)外观。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applySelectedMode() async {
        guard hasPendingChange else { return }

        isApplying = true
        errorMessage = nil
        statusMessage = "正在切换到\(selectedMode.title)外观..."

        do {
            let modeToApply = selectedMode
            try defaultsService.apply(selectedMode)
            snapshot = try defaultsService.readSnapshot()
            guard snapshot.mode == modeToApply else {
                throw AppearanceServiceError.defaultsVerificationFailed(expected: modeToApply, actual: snapshot.mode)
            }
            try relaunchService.relaunchFinder()
            statusMessage = "已切换到\(modeToApply.title)外观，并已重新启动 Finder。部分应用可能需要手动重启后生效。"
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "切换失败。"
        }

        isApplying = false
    }
}
