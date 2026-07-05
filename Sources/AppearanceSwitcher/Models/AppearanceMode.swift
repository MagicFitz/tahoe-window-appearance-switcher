import Foundation

enum AppearanceMode: String, CaseIterable, Identifiable {
    case rounded
    case classic
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rounded:
            "圆润"
        case .classic:
            "经典"
        case .custom:
            "自定义"
        }
    }

    var subtitle: String {
        switch self {
        case .rounded:
            "使用 Tahoe 风格"
        case .classic:
            "使用 Sequoia 风格"
        case .custom:
            "检测到当前值不是本工具的预设"
        }
    }

    var symbolName: String {
        switch self {
        case .rounded:
            "macwindow.on.rectangle"
        case .classic:
            "sidebar.left"
        case .custom:
            "slider.horizontal.3"
        }
    }
}

struct AppearanceSnapshot: Equatable {
    var windowCornerRadius: Double?
    var sidebarCornerRadius: Double?
    var floatingSidebar: Bool?

    var mode: AppearanceMode {
        if windowCornerRadius == nil,
           sidebarCornerRadius == nil,
           floatingSidebar == nil {
            return .rounded
        }

        if isClose(windowCornerRadius, to: 9),
           isClose(sidebarCornerRadius, to: 6),
           floatingSidebar == false {
            return .classic
        }

        return .custom
    }

    private func isClose(_ value: Double?, to target: Double) -> Bool {
        guard let value else { return false }
        return abs(value - target) < 0.001
    }
}
