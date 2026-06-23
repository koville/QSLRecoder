import Foundation

class GridLocator {
    // 将梅登海德网格定位转换为经纬度
    static func gridToLatLon(_ grid: String) -> (latitude: Double, longitude: Double)? {
        let grid = grid.uppercased()
        guard grid.count >= 4 else { return nil }
        
        let chars = Array(grid)
        
        // 场 (Field): 经度 A-R (18个), 纬度 A-R (18个)
        let lonField = Double(chars[0].asciiValue! - Character("A").asciiValue!)
        let latField = Double(chars[1].asciiValue! - Character("A").asciiValue!)
        
        // 方 (Square): 经度 0-9, 纬度 0-9
        guard let lonSquare = chars[2].wholeNumberValue,
              let latSquare = chars[3].wholeNumberValue else {
            return nil
        }
        
        // 计算中心点
        let longitude = (lonField * 20 + Double(lonSquare) * 2 + 1) - 180
        let latitude = (latField * 10 + Double(latSquare) + 0.5) - 90
        
        return (latitude, longitude)
    }
    
    // 将经纬度转换为梅登海德网格定位
    static func latLonToGrid(latitude: Double, longitude: Double) -> String {
        var lon = longitude + 180
        var lat = latitude + 90
        
        let lonField = Int(lon / 20)
        let latField = Int(lat / 10)
        
        lon -= Double(lonField) * 20
        lat -= Double(latField) * 10
        
        let lonSquare = Int(lon / 2)
        let latSquare = Int(lat)
        
        let field1 = Character(UnicodeScalar(lonField + 65)!)
        let field2 = Character(UnicodeScalar(latField + 65)!)
        let square1 = "\(lonSquare)"
        let square2 = "\(latSquare)"
        
        return "\(field1)\(field2)\(square1)\(square2)"
    }
}

class FrequencyUtils {
    // 频率到频段的映射
    static func frequencyToBand(_ freqMHz: Double) -> String {
        switch freqMHz {
        case 1.8...2.0: return "160m"
        case 3.5...4.0: return "80m"
        case 5.3...5.4: return "60m"
        case 7.0...7.3: return "40m"
        case 10.1...10.15: return "30m"
        case 14.0...14.35: return "20m"
        case 18.068...18.168: return "17m"
        case 21.0...21.45: return "15m"
        case 24.89...24.99: return "12m"
        case 28.0...29.7: return "10m"
        case 50...54: return "6m"
        case 144...148: return "2m"
        case 430...440: return "70cm"
        default: return ""
        }
    }
    
    // 频段到频率的映射（返回中心频率）
    static func bandToFrequency(_ band: String) -> Double {
        switch band {
        case "160m": return 1.9
        case "80m": return 3.7
        case "60m": return 5.35
        case "40m": return 7.1
        case "30m": return 10.12
        case "20m": return 14.15
        case "17m": return 18.1
        case "15m": return 21.2
        case "12m": return 24.94
        case "10m": return 28.5
        case "6m": return 50.1
        case "2m": return 144.0
        case "70cm": return 435.0
        default: return 0
        }
    }
}

class DateFormatter_UTC {
    static let shared = DateFormatter_UTC()
    
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let dateTimeFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        timeFormatter = DateFormatter()
        timeFormatter.timeZone = TimeZone(identifier: "UTC")
        timeFormatter.dateFormat = "HH:mm"
        
        dateTimeFormatter = DateFormatter()
        dateTimeFormatter.timeZone = TimeZone(identifier: "UTC")
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    }
    
    func formatDate(_ date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    func formatDateTime(_ date: Date) -> String {
        return dateTimeFormatter.string(from: date)
    }
}
