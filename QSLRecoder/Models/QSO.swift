import Foundation
import SwiftData

@Model
final class QSO {
    var id: UUID
    var callsign: String
    var datetimeOn: Date
    var datetimeOff: Date
    var frequency: Double
    var band: String
    var mode: String
    var rstSent: String
    var rstRcvd: String
    var txPwr: Double
    var qslSent: QSLStatus
    var qslRcvd: QSLStatus
    var qslSentDate: Date?
    var qslRcvdDate: Date?
    var qslVia: String
    var country: String
    var cqZone: Int
    var ituZone: Int
    var gridLocator: String
    var city: String
    var province: String
    var address: String
    var name: String
    var comment: String
    var repeaterName: String
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    
    init(
        id: UUID = UUID(),
        callsign: String = "",
        datetimeOn: Date = Date(),
        datetimeOff: Date = Date(),
        frequency: Double = 0.0,
        band: String = "",
        mode: String = "SSB",
        rstSent: String = "59",
        rstRcvd: String = "59",
        txPwr: Double = 10.0,
        qslSent: QSLStatus = .no,
        qslRcvd: QSLStatus = .no,
        qslSentDate: Date? = nil,
        qslRcvdDate: Date? = nil,
        qslVia: String = "",
        country: String = "",
        cqZone: Int = 0,
        ituZone: Int = 0,
        gridLocator: String = "",
        city: String = "",
        province: String = "",
        address: String = "",
        name: String = "",
        comment: String = "",
        repeaterName: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false
    ) {
        self.id = id
        self.callsign = callsign
        self.datetimeOn = datetimeOn
        self.datetimeOff = datetimeOff
        self.frequency = frequency
        self.band = band
        self.mode = mode
        self.rstSent = rstSent
        self.rstRcvd = rstRcvd
        self.txPwr = txPwr
        self.qslSent = qslSent
        self.qslRcvd = qslRcvd
        self.qslSentDate = qslSentDate
        self.qslRcvdDate = qslRcvdDate
        self.qslVia = qslVia
        self.country = country
        self.cqZone = cqZone
        self.ituZone = ituZone
        self.gridLocator = gridLocator
        self.city = city
        self.province = province
        self.address = address
        self.name = name
        self.comment = comment
        self.repeaterName = repeaterName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }
}

enum QSLStatus: String, Codable, CaseIterable {
    case yes = "Y"
    case no = "N"
    case requested = "R"
    case invalid = "I"
    
    var displayName: String {
        switch self {
        case .yes: return "已确认"
        case .no: return "未确认"
        case .requested: return "已请求"
        case .invalid: return "无效"
        }
    }
}
