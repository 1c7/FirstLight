import Foundation

struct DebugSimulation {
    let lux: Double?
    let accumulatedMinutes: Double
}

enum DebugPreset: Int, CaseIterable {
    case live
    case sensorUnavailable
    case tooDark
    case usefulLight
    case nearGoal
    case achieved
    case custom

    var title: String {
        switch self {
        case .live: return L10n.text("实时传感器", "Live Sensor")
        case .sensorUnavailable: return L10n.text("传感器不可用", "Sensor Unavailable")
        case .tooDark: return L10n.text("光线太暗", "Too Dark")
        case .usefulLight: return L10n.text("有效光照", "Useful Light")
        case .nearGoal: return L10n.text("接近达标", "Near Goal")
        case .achieved: return L10n.text("已经达标", "Goal Achieved")
        case .custom: return L10n.text("自定义", "Custom")
        }
    }

    var simulation: DebugSimulation? {
        let target = DoseCalculator.targetEffectiveMinutes
        switch self {
        case .live: return nil
        case .sensorUnavailable: return DebugSimulation(lux: nil, accumulatedMinutes: 0)
        case .tooDark: return DebugSimulation(lux: 120, accumulatedMinutes: 4)
        case .usefulLight: return DebugSimulation(lux: 2_500, accumulatedMinutes: 7)
        case .nearGoal: return DebugSimulation(lux: 8_000, accumulatedMinutes: max(0, target - 2))
        case .achieved: return DebugSimulation(lux: 10_000, accumulatedMinutes: target + 1)
        case .custom: return nil
        }
    }
}
