import AppTrackingTransparency
import AdSupport

class TrackingTransparencyService {
    static let shared = TrackingTransparencyService()
    
    func requestTrackingPermission() {
        // Only request if iOS 14+
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Tracking authorized")
                    // Analytics can proceed
                case .denied:
                    print("Tracking denied")
                    // Analytics disabled
                case .restricted:
                    print("Tracking restricted")
                case .notDetermined:
                    print("Tracking not determined")
                @unknown default:
                    print("Unknown tracking status")
                }
            }
        }
    }
    
    var trackingAuthorizationStatus: String {
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .authorized:
                return "authorized"
            case .denied:
                return "denied"
            case .restricted:
                return "restricted"
            case .notDetermined:
                return "notDetermined"
            @unknown default:
                return "unknown"
            }
        }
        return "not applicable"
    }
    
    var canTrack: Bool {
        if #available(iOS 14, *) {
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        }
        return true
    }
}
