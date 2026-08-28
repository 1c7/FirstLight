import Foundation
import IOKit

// Reads the built-in ambient light sensor's live lux value via a fully
// PUBLIC, documented IOKit registry API -- no private/undocumented
// symbols are used here.
//
// Background (verified empirically on this exact machine -- 2022
// MacBook Air, M2, Mac14,2 -- on 2026-08-28, before this file was
// written):
//
//   `ioreg -p IOService -n als -l` shows the built-in ALS as a
//   descendant chain: `als` (AppleSPUHIDInterface) -> AppleSPUHIDDevice
//   -> IOHIDInterface -> `AppleSPUVD6286` (the actual sensor driver
//   class). That `AppleSPUVD6286` IOService node carries a "CurrentLux"
//   property that:
//     - reads back a plausible, non-garbage lux number (order of
//       hundreds indoors -- 833, later 917 -- not NaN/stuck/absurd),
//     - genuinely changed value between polls taken minutes apart
//       (833 -> 917) with no code changes, proving it's live and not a
//       boot-time snapshot, and
//     - lives right next to a sibling IOHIDEventServiceUserClient whose
//       "EnqueueEventCount" for HID event type 12
//       (kIOHIDEventTypeAmbientLightSensor) was seen incrementing every
//       few seconds during polling -- proof the underlying sensor is
//       continuously streaming reports, which this property tracks.
//
// The original plan (before this was found) was to go through Apple's
// private/undocumented `IOHIDEventSystemClient` HID event API -- the
// same family of private calls Lunar (https://github.com/alin23/Lunar)
// uses for display/sensor plumbing. That path was prototyped first: it
// linked fine, but `IOHIDServiceClientCopyEvent` never returned an event
// for this device's HID service on this OS/hardware combination (the
// service enumerates under a vendor-specific usage page, not the
// standard HID "Ambient Light" usage, and account for that or not, the
// synchronous copy call came back null every time). Reading
// "CurrentLux" straight off the IOKit registry turned out to be simpler
// AND fully public/documented, so that's what's used here. No private
// API is used anywhere in this app.
//
// Caveat: "AppleSPUVD6286" is this Mac's specific ALS driver class name
// and "CurrentLux" is an undocumented (if publicly-readable) property
// key on it -- neither is a stable, Apple-guaranteed contract. A future
// macOS update or different Apple Silicon generation could rename the
// class or the property. If `readLux()` starts returning nil, re-run
// `ioreg -p IOService -n als -l` and look for whichever node under the
// `als` chain currently exposes a live-looking numeric property.
enum AmbientLightSensor {
    private static let driverClassName = "AppleSPUVD6286" as CFString
    private static let luxPropertyKey = "CurrentLux" as CFString

    /// Returns the current lux reading, or nil if the sensor's IOService
    /// node or property could not be found.
    static func readLux() -> Double? {
        let matching = IOServiceMatching((driverClassName as String))
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        guard let cfValue = IORegistryEntryCreateCFProperty(service, luxPropertyKey, kCFAllocatorDefault, 0) else {
            return nil
        }
        let value = cfValue.takeRetainedValue()
        guard let num = value as? NSNumber else { return nil }
        return num.doubleValue
    }
}
