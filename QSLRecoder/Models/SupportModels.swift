import Foundation

struct CallsignInfo: Codable {
    var callsign: String
    var country: String
    var cqZone: Int
    var ituZone: Int
    var continent: String
    var latitude: Double
    var longitude: Double
    var gridLocator: String
    var utcOffset: Double
    
    init(
        callsign: String = "",
        country: String = "",
        cqZone: Int = 0,
        ituZone: Int = 0,
        continent: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        gridLocator: String = "",
        utcOffset: Double = 0.0
    ) {
        self.callsign = callsign
        self.country = country
        self.cqZone = cqZone
        self.ituZone = ituZone
        self.continent = continent
        self.latitude = latitude
        self.longitude = longitude
        self.gridLocator = gridLocator
        self.utcOffset = utcOffset
    }
}

struct ADIFRecord: Codable {
    var fields: [String: String]
    
    init(fields: [String: String] = [:]) {
        self.fields = fields
    }
    
    subscript(key: String) -> String? {
        get { fields[key.uppercased()] }
        set { fields[key.uppercased()] = newValue }
    }
}

struct ExportSettings {
    var format: ExportFormat
    var dateRange: DateRange?
    var includeDeleted: Bool
    var qslOnly: Bool
    
    init(
        format: ExportFormat = .adif,
        dateRange: DateRange? = nil,
        includeDeleted: Bool = false,
        qslOnly: Bool = false
    ) {
        self.format = format
        self.dateRange = dateRange
        self.includeDeleted = includeDeleted
        self.qslOnly = qslOnly
    }
}

enum ExportFormat: String, CaseIterable {
    case adif = "ADIF"
    case csv = "CSV"
}

struct DateRange {
    var start: Date
    var end: Date
    
    init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

struct StatisticsData {
    var totalQSOs: Int
    var qsoByBand: [String: Int]
    var qsoByMode: [String: Int]
    var qsoByCountry: [String: Int]
    var qsoByMonth: [String: Int]
    var qslSentCount: Int
    var qslRcvdCount: Int
    var qslConfirmedCount: Int
    var dxccCount: Int
    var wazCount: Int
    
    init(
        totalQSOs: Int = 0,
        qsoByBand: [String: Int] = [:],
        qsoByMode: [String: Int] = [:],
        qsoByCountry: [String: Int] = [:],
        qsoByMonth: [String: Int] = [:],
        qslSentCount: Int = 0,
        qslRcvdCount: Int = 0,
        qslConfirmedCount: Int = 0,
        dxccCount: Int = 0,
        wazCount: Int = 0
    ) {
        self.totalQSOs = totalQSOs
        self.qsoByBand = qsoByBand
        self.qsoByMode = qsoByMode
        self.qsoByCountry = qsoByCountry
        self.qsoByMonth = qsoByMonth
        self.qslSentCount = qslSentCount
        self.qslRcvdCount = qslRcvdCount
        self.qslConfirmedCount = qslConfirmedCount
        self.dxccCount = dxccCount
        self.wazCount = wazCount
    }
}
