import Foundation

class CallsignLookupService {
    // 内置呼号前缀数据库
    private let prefixDatabase: [String: CallsignInfo] = [
        "BV": CallsignInfo(callsign: "BV", country: "台湾", cqZone: 24, ituZone: 44, continent: "AS", utcOffset: 8),
        "BA": CallsignInfo(callsign: "BA", country: "中国", cqZone: 24, ituZone: 44, continent: "AS", utcOffset: 8),
        "BD": CallsignInfo(callsign: "BD", country: "中国", cqZone: 24, ituZone: 44, continent: "AS", utcOffset: 8),
        "BG": CallsignInfo(callsign: "BG", country: "中国", cqZone: 24, ituZone: 44, continent: "AS", utcOffset: 8),
        "BI": CallsignInfo(callsign: "BI", country: "中国", cqZone: 24, ituZone: 44, continent: "AS", utcOffset: 8),
        "BH": CallsignInfo(callsign: "BH", country: "中国", cqZone: 24, ituZone: 44, continent: "AS", utcOffset: 8),
        "JA": CallsignInfo(callsign: "JA", country: "日本", cqZone: 25, ituZone: 45, continent: "AS", utcOffset: 9),
        "JH": CallsignInfo(callsign: "JH", country: "日本", cqZone: 25, ituZone: 45, continent: "AS", utcOffset: 9),
        "JR": CallsignInfo(callsign: "JR", country: "日本", cqZone: 25, ituZone: 45, continent: "AS", utcOffset: 9),
        "W": CallsignInfo(callsign: "W", country: "美国", cqZone: 3, ituZone: 8, continent: "NA", utcOffset: -5),
        "K": CallsignInfo(callsign: "K", country: "美国", cqZone: 3, ituZone: 8, continent: "NA", utcOffset: -5),
        "N": CallsignInfo(callsign: "N", country: "美国", cqZone: 3, ituZone: 8, continent: "NA", utcOffset: -5),
        "DL": CallsignInfo(callsign: "DL", country: "德国", cqZone: 14, ituZone: 28, continent: "EU", utcOffset: 1),
        "DA": CallsignInfo(callsign: "DA", country: "德国", cqZone: 14, ituZone: 28, continent: "EU", utcOffset: 1),
        "DB": CallsignInfo(callsign: "DB", country: "德国", cqZone: 14, ituZone: 28, continent: "EU", utcOffset: 1),
        "DC": CallsignInfo(callsign: "DC", country: "德国", cqZone: 14, ituZone: 28, continent: "EU", utcOffset: 1),
        "DD": CallsignInfo(callsign: "DD", country: "德国", cqZone: 14, ituZone: 28, continent: "EU", utcOffset: 1),
        "G": CallsignInfo(callsign: "G", country: "英国", cqZone: 14, ituZone: 27, continent: "EU", utcOffset: 0),
        "M": CallsignInfo(callsign: "M", country: "英国", cqZone: 14, ituZone: 27, continent: "EU", utcOffset: 0),
        "F": CallsignInfo(callsign: "F", country: "法国", cqZone: 14, ituZone: 27, continent: "EU", utcOffset: 1),
        "I": CallsignInfo(callsign: "I", country: "意大利", cqZone: 15, ituZone: 28, continent: "EU", utcOffset: 1),
        "EA": CallsignInfo(callsign: "EA", country: "西班牙", cqZone: 14, ituZone: 37, continent: "EU", utcOffset: 1),
        "VK": CallsignInfo(callsign: "VK", country: "澳大利亚", cqZone: 30, ituZone: 59, continent: "OC", utcOffset: 10),
        "VE": CallsignInfo(callsign: "VE", country: "加拿大", cqZone: 3, ituZone: 4, continent: "NA", utcOffset: -5),
        "UA": CallsignInfo(callsign: "UA", country: "俄罗斯", cqZone: 16, ituZone: 29, continent: "EU", utcOffset: 3),
        "RA": CallsignInfo(callsign: "RA", country: "俄罗斯", cqZone: 16, ituZone: 29, continent: "EU", utcOffset: 3),
        "ZS": CallsignInfo(callsign: "ZS", country: "南非", cqZone: 38, ituZone: 57, continent: "AF", utcOffset: 2),
        "PY": CallsignInfo(callsign: "PY", country: "巴西", cqZone: 11, ituZone: 15, continent: "SA", utcOffset: -3),
        "HL": CallsignInfo(callsign: "HL", country: "韩国", cqZone: 25, ituZone: 44, continent: "AS", utcOffset: 9),
        "DS": CallsignInfo(callsign: "DS", country: "韩国", cqZone: 25, ituZone: 44, continent: "AS", utcOffset: 9),
        "HS": CallsignInfo(callsign: "HS", country: "泰国", cqZone: 26, ituZone: 49, continent: "AS", utcOffset: 7),
        "9V": CallsignInfo(callsign: "9V", country: "新加坡", cqZone: 26, ituZone: 51, continent: "AS", utcOffset: 8),
        "9M": CallsignInfo(callsign: "9M", country: "马来西亚", cqZone: 28, ituZone: 54, continent: "AS", utcOffset: 8),
        "YB": CallsignInfo(callsign: "YB", country: "印度尼西亚", cqZone: 28, ituZone: 51, continent: "AS", utcOffset: 7),
        "VU": CallsignInfo(callsign: "VU", country: "印度", cqZone: 22, ituZone: 41, continent: "AS", utcOffset: 5.5),
        "4X": CallsignInfo(callsign: "4X", country: "以色列", cqZone: 20, ituZone: 39, continent: "AS", utcOffset: 2),
        "A7": CallsignInfo(callsign: "A7", country: "卡塔尔", cqZone: 21, ituZone: 39, continent: "AS", utcOffset: 3),
        "A6": CallsignInfo(callsign: "A6", country: "阿联酋", cqZone: 21, ituZone: 39, continent: "AS", utcOffset: 4),
        "SV": CallsignInfo(callsign: "SV", country: "希腊", cqZone: 20, ituZone: 28, continent: "EU", utcOffset: 2),
        "OK": CallsignInfo(callsign: "OK", country: "捷克", cqZone: 15, ituZone: 28, continent: "EU", utcOffset: 1),
        "OE": CallsignInfo(callsign: "OE", country: "奥地利", cqZone: 15, ituZone: 28, continent: "EU", utcOffset: 1),
        "HB": CallsignInfo(callsign: "HB", country: "瑞士", cqZone: 14, ituZone: 28, continent: "EU", utcOffset: 1),
        "ON": CallsignInfo(callsign: "ON", country: "比利时", cqZone: 14, ituZone: 27, continent: "EU", utcOffset: 1),
        "PA": CallsignInfo(callsign: "PA", country: "荷兰", cqZone: 14, ituZone: 27, continent: "EU", utcOffset: 1),
        "OZ": CallsignInfo(callsign: "OZ", country: "丹麦", cqZone: 14, ituZone: 18, continent: "EU", utcOffset: 1),
        "SM": CallsignInfo(callsign: "SM", country: "瑞典", cqZone: 14, ituZone: 18, continent: "EU", utcOffset: 1),
        "LA": CallsignInfo(callsign: "LA", country: "挪威", cqZone: 14, ituZone: 18, continent: "EU", utcOffset: 1),
        "OH": CallsignInfo(callsign: "OH", country: "芬兰", cqZone: 15, ituZone: 18, continent: "EU", utcOffset: 2),
        "SP": CallsignInfo(callsign: "SP", country: "波兰", cqZone: 15, ituZone: 28, continent: "EU", utcOffset: 1),
        "HA": CallsignInfo(callsign: "HA", country: "匈牙利", cqZone: 15, ituZone: 28, continent: "EU", utcOffset: 1),
        "YO": CallsignInfo(callsign: "YO", country: "罗马尼亚", cqZone: 15, ituZone: 28, continent: "EU", utcOffset: 2),
        "LZ": CallsignInfo(callsign: "LZ", country: "保加利亚", cqZone: 20, ituZone: 28, continent: "EU", utcOffset: 2),
        "CT": CallsignInfo(callsign: "CT", country: "葡萄牙", cqZone: 14, ituZone: 37, continent: "EU", utcOffset: 0),
    }
    
    func lookup(_ callsign: String) -> CallsignInfo? {
        let uppercased = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uppercased.isEmpty else { return nil }
        
        // Try progressively shorter prefixes
        for length in stride(from: min(3, uppercased.count), through: 1, by: -1) {
            let prefix = String(uppercased.prefix(length))
            if let info = prefixDatabase[prefix] {
                var result = info
                result.callsign = uppercased
                return result
            }
        }
        
        return nil
    }
    
    func lookupOnline(_ callsign: String) async throws -> CallsignInfo? {
        // 使用 QRZ.com XML API (需要订阅)
        // 这里提供一个示例实现
        let urlString = "https://xml.callook.info/api/callsign/\(callsign)/json"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct CallookResponse: Codable {
            struct Current: Codable {
                let callsign: String
                let opsClass: String?
                let grid: String?
            }
            struct Previous: Codable {
                let callsign: String?
            }
            struct Location: Codable {
                let state: String?
                let county: String?
                let country: String?
            }
            
            let current: Current?
            let previous: Previous?
            let location: Location?
        }
        
        let response = try JSONDecoder().decode(CallookResponse.self, from: data)
        
        if let current = response.current {
            var info = CallsignInfo()
            info.callsign = current.callsign
            info.gridLocator = current.grid ?? ""
            info.country = response.location?.country ?? "美国"
            return info
        }
        
        return nil
    }
}
