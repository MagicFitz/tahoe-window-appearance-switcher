import Foundation

protocol AppearanceDefaultsServicing {
    func readSnapshot() throws -> AppearanceSnapshot
    func apply(_ mode: AppearanceMode) throws
}

struct DefaultsAppearanceService: AppearanceDefaultsServicing {
    private let defaultsPath = "/usr/bin/defaults"

    func readSnapshot() throws -> AppearanceSnapshot {
        AppearanceSnapshot(
            windowCornerRadius: readDouble("NSConvolutionOverride1"),
            sidebarCornerRadius: readDouble("NSSplitViewItemGlassMinimumCornerRadius"),
            floatingSidebar: readBool("NSSplitViewItemSidebarDefaultsToFloatingAppearance")
        )
    }

    func apply(_ mode: AppearanceMode) throws {
        switch mode {
        case .classic:
            try write("NSConvolutionOverride1", type: "-float", value: "9")
            try write("NSSplitViewItemGlassMinimumCornerRadius", type: "-float", value: "6")
            try write("NSSplitViewItemSidebarDefaultsToFloatingAppearance", type: "-bool", value: "false")
        case .rounded:
            try deleteIfPresent("NSConvolutionOverride1")
            try deleteIfPresent("NSSplitViewItemGlassMinimumCornerRadius")
            try deleteIfPresent("NSSplitViewItemSidebarDefaultsToFloatingAppearance")
        case .custom:
            break
        }
    }

    private func readDouble(_ key: String) -> Double? {
        guard let value = try? read(key), !value.isEmpty else { return nil }
        return Double(value)
    }

    private func readBool(_ key: String) -> Bool? {
        guard let value = try? read(key), !value.isEmpty else { return nil }
        switch value.lowercased() {
        case "1", "true", "yes":
            return true
        case "0", "false", "no":
            return false
        default:
            return nil
        }
    }

    private func read(_ key: String) throws -> String {
        let result = try ProcessRunner.run(defaultsPath, ["read", "-g", key])
        return result.succeeded ? result.output : ""
    }

    private func write(_ key: String, type: String, value: String) throws {
        let result = try ProcessRunner.run(defaultsPath, ["write", "-g", key, type, value])
        if !result.succeeded {
            throw AppearanceServiceError.defaultsWriteFailed(result.error)
        }
    }

    private func deleteIfPresent(_ key: String) throws {
        let existingValue = try ProcessRunner.run(defaultsPath, ["read", "-g", key])
        guard existingValue.succeeded else { return }

        let result = try ProcessRunner.run(defaultsPath, ["delete", "-g", key])
        if !result.succeeded {
            throw AppearanceServiceError.defaultsDeleteFailed(result.error)
        }
    }
}

enum AppearanceServiceError: LocalizedError {
    case defaultsWriteFailed(String)
    case defaultsDeleteFailed(String)
    case defaultsVerificationFailed(expected: AppearanceMode, actual: AppearanceMode)
    case relaunchFailed(String)

    var errorDescription: String? {
        switch self {
        case .defaultsWriteFailed(let message):
            "写入系统外观设置失败：\(message.isEmpty ? "未知错误" : message)"
        case .defaultsDeleteFailed(let message):
            "恢复系统默认外观失败：\(message.isEmpty ? "未知错误" : message)"
        case .defaultsVerificationFailed(let expected, let actual):
            "外观设置写入后未生效：期望为\(expected.title)，当前为\(actual.title)。"
        case .relaunchFailed(let message):
            "重启应用失败：\(message)"
        }
    }
}
