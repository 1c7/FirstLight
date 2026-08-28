import Darwin
import Foundation
import IOKit

// Reads the built-in ambient light sensor through the public IOKit registry API.
// `CurrentLux` is not an Apple-guaranteed property, so discovery has two paths:
// a fast match for the driver verified on the original test machine, followed by
// a recursive registry search for whichever service exposes a numeric CurrentLux.
enum AmbientLightSensor {
    private static let knownDriverClassName = "AppleSPUVD6286"
    private static let luxPropertyKey = "CurrentLux" as CFString
    private static var cachedService: io_service_t = 0
    private static var discoveryMethod = "not discovered"
    private static var discoveredClassName = "unknown"

    static func readLux() -> Double? {
        if cachedService != 0, let value = luxValue(from: cachedService) {
            return value
        }

        releaseCachedService()
        guard let service = locateSensorService() else { return nil }
        cachedService = service
        return luxValue(from: service)
    }

    private static func locateSensorService() -> io_service_t? {
        if let matching = IOServiceMatching(knownDriverClassName) {
            let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
            if service != 0, luxValue(from: service) != nil {
                recordDiscovery(service: service, method: "known-driver fast path")
                return service
            }
            if service != 0 { IOObjectRelease(service) }
        }

        var iterator: io_iterator_t = 0
        let result = IORegistryCreateIterator(
            kIOMainPortDefault,
            kIOServicePlane,
            IOOptionBits(kIORegistryIterateRecursively),
            &iterator
        )
        guard result == KERN_SUCCESS else {
            discoveryMethod = "registry iterator failed (\(result))"
            return nil
        }
        defer { IOObjectRelease(iterator) }

        while true {
            let service = IOIteratorNext(iterator)
            guard service != 0 else { break }
            if luxValue(from: service) != nil {
                recordDiscovery(service: service, method: "CurrentLux registry discovery")
                return service
            }
            IOObjectRelease(service)
        }
        discoveryMethod = "no numeric CurrentLux property found"
        discoveredClassName = "unknown"
        return nil
    }

    private static func luxValue(from service: io_service_t) -> Double? {
        guard let unmanaged = IORegistryEntryCreateCFProperty(
            service, luxPropertyKey, kCFAllocatorDefault, 0
        ) else { return nil }
        guard let number = unmanaged.takeRetainedValue() as? NSNumber else { return nil }
        let value = number.doubleValue
        return value.isFinite && value >= 0 ? value : nil
    }

    private static func recordDiscovery(service: io_service_t, method: String) {
        discoveryMethod = method
        if let unmanagedClass = IOObjectCopyClass(service) {
            discoveredClassName = unmanagedClass.takeRetainedValue() as String
        } else {
            discoveredClassName = "unknown"
        }
    }

    private static func releaseCachedService() {
        if cachedService != 0 {
            IOObjectRelease(cachedService)
            cachedService = 0
        }
    }

    static func diagnosticReport() -> String {
        _ = readLux()
        let value = cachedService == 0 ? "unavailable" : "available"
        return [
            "FirstLight sensor diagnostics",
            "Mac model: \(hardwareModel())",
            "macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "Sensor: \(value)",
            "Driver class: \(discoveredClassName)",
            "Discovery: \(discoveryMethod)",
        ].joined(separator: "\n")
    }

    private static func hardwareModel() -> String {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 else {
            return "unknown"
        }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &buffer, &size, nil, 0) == 0 else {
            return "unknown"
        }
        return String(cString: buffer)
    }
}
