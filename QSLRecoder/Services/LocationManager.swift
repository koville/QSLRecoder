import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private var completion: ((CLLocation?, String?) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
    }
    
    func requestLocation(completion: @escaping (CLLocation?, String?) -> Void) {
        self.completion = completion
        self.errorMessage = nil
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(nil, "位置权限被拒绝，请在设置中启用位置服务")
        @unknown default:
            completion(nil, "未知的授权状态")
        }
    }
    
    func getCurrentGridLocator(completion: @escaping (String?, String?) -> Void) {
        requestLocation { [weak self] location, error in
            guard let location = location else {
                completion(nil, error)
                return
            }
            
            let grid = GridLocator.latLonToGrid(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            completion(grid, nil)
        }
    }
    
    func getCurrentLocationInfo(completion: @escaping (String?, String?, String?, String?, String?) -> Void) {
        requestLocation { [weak self] location, error in
            guard let location = location else {
                completion(nil, nil, nil, nil, error)
                return
            }
            
            let grid = GridLocator.latLonToGrid(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            // Reverse geocoding to get address
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? ""
                    let province = placemark.administrativeArea ?? ""
                    let address = [placemark.subLocality, placemark.thoroughfare, placemark.subThoroughfare]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    completion(grid, city, province, address, nil)
                } else {
                    completion(grid, "", "", "", nil)
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            completion?(nil, "位置权限被拒绝")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        completion?(location, nil)
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message: String
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                message = "位置权限被拒绝"
            case .locationUnknown:
                message = "无法获取位置，请稍后重试"
            case .network:
                message = "网络错误，无法获取位置"
            default:
                message = "位置获取失败: \(error.localizedDescription)"
            }
        } else {
            message = "位置获取失败: \(error.localizedDescription)"
        }
        
        errorMessage = message
        completion?(nil, message)
        completion = nil
    }
}
