import Foundation

enum TunnelAddressMatcher {
    static func matches(targetIP: String, interfaceIP: String, isTunnel: Bool) -> Bool {
        if interfaceIP == targetIP { return true }
        guard isTunnel else { return false }
        let target = targetIP.split(separator: ".")
        let address = interfaceIP.split(separator: ".")
        guard target.count == 4, address.count == 4 else { return false }
        if target.dropLast().elementsEqual(address.dropLast()) { return true }
        // LocalDevVPN's device endpoint and this phone's VPN interface are different.
        return targetIP == "10.7.0.1" && interfaceIP == "10.7.1.1"
    }
}
