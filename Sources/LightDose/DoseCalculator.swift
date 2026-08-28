import Foundation

// Ports the dose math from the Flutter reference app's
// lib/dose_calculator.dart exactly -- same constants, same formulas.
// Do not change these numbers without re-checking that file; they are
// calibrated against the published ED50 half-saturation anchor for
// light-driven circadian phase shifting (see that project's
// doc/4-每日剂量计算公式的科学依据.md).
enum DoseCalculator {
    static let luxHalfSaturation = 100.0
    static let referenceLux = 10000.0
    static let referenceMinutes = 20.0

    // Below this lux, light is treated as circadian-useless: accumulation
    // pauses and the UI should say so instead of showing a countdown.
    static let uselessBelowLux = 500.0

    /// Maps a lux reading to a weight in [0, 1).
    static func weight(_ lux: Double) -> Double {
        guard lux > 0 else { return 0.0 }
        return lux / (lux + luxHalfSaturation)
    }

    /// Effective minutes needed per day to hit target, calibrated as
    /// "10000 lux held for 20 minutes" expressed through the same weight
    /// curve.
    static let targetEffectiveMinutes: Double = referenceMinutes * weight(referenceLux)

    /// Effective minutes contributed by holding `lux` for `elapsedSeconds`.
    static func effectiveMinutes(forLux lux: Double, elapsedSeconds: Double) -> Double {
        return weight(lux) * elapsedSeconds / 60.0
    }

    /// Whether the current lux is bright enough to be circadian-useful.
    static func isCurrentLightUseful(_ currentLux: Double) -> Bool {
        return currentLux >= uselessBelowLux
    }

    /// Real minutes remaining at the current lux to reach today's target.
    /// Returns nil when the current light is not useful (too dim).
    static func remainingRealMinutes(currentLux: Double, accumulatedEffectiveMinutes: Double) -> Double? {
        guard isCurrentLightUseful(currentLux) else { return nil }
        let remainingEffective = targetEffectiveMinutes - accumulatedEffectiveMinutes
        if remainingEffective <= 0 { return 0.0 }
        return remainingEffective / weight(currentLux)
    }

    /// Whether the accumulated total has reached today's target.
    static func isAchieved(_ accumulatedEffectiveMinutes: Double) -> Bool {
        return accumulatedEffectiveMinutes >= targetEffectiveMinutes
    }
}
