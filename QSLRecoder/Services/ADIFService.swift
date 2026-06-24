import Foundation
import SwiftData

class ADIFService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Import
    
    func importADIF(from url: URL) async throws -> Int {
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw ADIFError.invalidFormat
        }
        
        let records = parseADIF(content)
        var importedCount = 0
        
        for record in records {
            do {
                let qso = try createQSO(from: record)
                modelContext.insert(qso)
                importedCount += 1
            } catch {
                print("Failed to import record: \(error)")
                continue
            }
        }
        
        try modelContext.save()
        return importedCount
    }
    
    private func parseADIF(_ content: String) -> [[String: String]] {
        var records: [[String: String]] = []
        var currentRecord: [String: String] = [:]
        
        // Remove header if present
        let lines = content.components(separatedBy: "<EOH>").dropFirst()
        let dataSection = lines.joined(separator: "")
        
        // Split by record separator
        let recordStrings = dataSection.components(separatedBy: "<EOR>")
        
        for recordString in recordStrings {
            currentRecord = [:]
            let fields = recordString.components(separatedBy: "<")
            
            for field in fields {
                if field.isEmpty { continue }
                
                // Parse field: FIELDNAME:LENGTH:TYPE data
                let parts = field.components(separatedBy: ":")
                if parts.count >= 2 {
                    let fieldName = parts[0].uppercased()
                    let valueParts = parts[1].components(separatedBy: ">")
                    if valueParts.count >= 2 {
                        let value = valueParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        currentRecord[fieldName] = value
                    }
                }
            }
            
            if !currentRecord.isEmpty {
                records.append(currentRecord)
            }
        }
        
        return records
    }
    
    private func createQSO(from record: [String: String]) throws -> QSO {
        let qso = QSO()
        
        // Required fields
        qso.callsign = record["CALL"] ?? ""
        
        // Date/Time
        if let dateStr = record["QSO_DATE"], let timeStr = record["TIME_ON"] {
            qso.datetimeOn = parseDateTime(date: dateStr, time: timeStr)
        }
        if let dateStr = record["QSO_DATE_OFF"] ?? record["QSO_DATE"], 
           let timeStr = record["TIME_OFF"] ?? record["TIME_ON"] {
            qso.datetimeOff = parseDateTime(date: dateStr, time: timeStr)
        }
        
        // Frequency and band
        if let freqStr = record["FREQ"] {
            qso.frequency = Double(freqStr) ?? 0
        }
        qso.band = record["BAND"] ?? ""
        qso.mode = record["MODE"] ?? ""
        
        // Signal reports
        qso.rstSent = record["RST_SENT"] ?? "59"
        qso.rstRcvd = record["RST_RCVD"] ?? "59"
        
        // Power
        if let pwrStr = record["TX_PWR"] {
            qso.txPwr = Double(pwrStr) ?? 0
        }
        
        // QSL status
        qso.qslSent = parseQSLStatus(record["QSL_SENT"])
        qso.qslRcvd = parseQSLStatus(record["QSL_RCVD"])
        
        if let dateStr = record["QSLSDATE"] {
            qso.qslSentDate = parseDate(dateStr)
        }
        if let dateStr = record["QSLRDATE"] {
            qso.qslRcvdDate = parseDate(dateStr)
        }
        
        qso.qslVia = record["QSL_VIA"] ?? ""
        
        // Station info
        qso.country = record["COUNTRY"] ?? ""
        qso.name = record["NAME"] ?? ""
        qso.gridLocator = record["GRIDSQUARE"] ?? ""
        qso.city = record["QTH"] ?? ""
        qso.province = record["STATE"] ?? ""
        qso.address = record["ADDRESS"] ?? ""
        qso.repeaterName = record["APP_QSLRECODER_REPEATER"] ?? ""
        qso.comment = record["COMMENT"] ?? ""
        
        if let cqStr = record["CQZ"] {
            qso.cqZone = Int(cqStr) ?? 0
        }
        if let ituStr = record["ITUZ"] {
            qso.ituZone = Int(ituStr) ?? 0
        }
        
        return qso
    }
    
    private func parseDateTime(date: String, time: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        // Try different formats
        let formats = [
            "yyyyMMddHHmmss",
            "yyyyMMdd HHmmss",
            "yyyyMMddHHmm",
            "yyyyMMdd HHmm"
        ]
        
        let dateTimeStr = date + time
        
        for format in formats {
            formatter.dateFormat = format
            if let parsedDate = formatter.date(from: dateTimeStr) {
                return parsedDate
            }
        }
        
        return Date()
    }
    
    private func parseDate(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.date(from: dateStr)
    }
    
    private func parseQSLStatus(_ status: String?) -> QSLStatus {
        guard let status = status else { return .no }
        
        switch status.uppercased() {
        case "Y": return .yes
        case "R": return .requested
        case "I": return .invalid
        default: return .no
        }
    }
    
    // MARK: - Export
    
    func exportADIF(qsos: [QSO]) -> String {
        var adif = ""
        
        // Header
        adif += "ADIF Export from QSLRecoder\n"
        adif += "Generated: \(Date().formatted())\n"
        adif += "<ADIF_VER:5>3.1.4\n"
        adif += "<PROGRAMID:10>QSLRecoder\n"
        adif += "<EOH>\n\n"
        
        // Records
        for qso in qsos {
            adif += exportQSO(qso)
            adif += "<EOR>\n"
        }
        
        return adif
    }
    
    private func exportQSO(_ qso: QSO) -> String {
        var record = ""
        
        record += formatField("CALL", qso.callsign)
        record += formatField("QSO_DATE", formatDate(qso.datetimeOn))
        record += formatField("TIME_ON", formatTime(qso.datetimeOn))
        record += formatField("QSO_DATE_OFF", formatDate(qso.datetimeOff))
        record += formatField("TIME_OFF", formatTime(qso.datetimeOff))
        
        if qso.frequency > 0 {
            record += formatField("FREQ", String(format: "%.6f", qso.frequency))
        }
        if !qso.band.isEmpty {
            record += formatField("BAND", qso.band)
        }
        if !qso.mode.isEmpty {
            record += formatField("MODE", qso.mode)
        }
        
        record += formatField("RST_SENT", qso.rstSent)
        record += formatField("RST_RCVD", qso.rstRcvd)
        
        if qso.txPwr > 0 {
            record += formatField("TX_PWR", String(format: "%.1f", qso.txPwr))
        }
        
        record += formatField("QSL_SENT", qso.qslSent.rawValue)
        record += formatField("QSL_RCVD", qso.qslRcvd.rawValue)
        
        if let date = qso.qslSentDate {
            record += formatField("QSLSDATE", formatDate(date))
        }
        if let date = qso.qslRcvdDate {
            record += formatField("QSLRDATE", formatDate(date))
        }
        
        if !qso.qslVia.isEmpty {
            record += formatField("QSL_VIA", qso.qslVia)
        }
        if !qso.country.isEmpty {
            record += formatField("COUNTRY", qso.country)
        }
        if !qso.name.isEmpty {
            record += formatField("NAME", qso.name)
        }
        if !qso.gridLocator.isEmpty {
            record += formatField("GRIDSQUARE", qso.gridLocator)
        }
        if !qso.city.isEmpty {
            record += formatField("QTH", qso.city)
        }
        if !qso.province.isEmpty {
            record += formatField("STATE", qso.province)
        }
        if !qso.address.isEmpty {
            record += formatField("ADDRESS", qso.address)
        }
        if !qso.repeaterName.isEmpty {
            record += formatField("APP_QSLRECODER_REPEATER", qso.repeaterName)
        }
        if !qso.comment.isEmpty {
            record += formatField("COMMENT", qso.comment)
        }
        if qso.cqZone > 0 {
            record += formatField("CQZ", String(qso.cqZone))
        }
        if qso.ituZone > 0 {
            record += formatField("ITUZ", String(qso.ituZone))
        }
        
        return record
    }
    
    private func formatField(_ name: String, _ value: String) -> String {
        return "<\(name):\(value.count)>\(value)\n"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "HHmmss"
        return formatter.string(from: date)
    }
    
    // MARK: - CSV Export
    
    func exportCSV(qsos: [QSO]) -> String {
        var csv = "呼号,日期,时间,频段,模式,发送RST,接收RST,功率,国家,省份,城市,地址,CQ区,ITU区,网格,中继台,QSL发送,QSL接收,备注\n"
        
        for qso in qsos {
            let date = formatDate(qso.datetimeOn)
            let time = formatTime(qso.datetimeOn)
            
            csv += "\(qso.callsign),"
            csv += "\(date),"
            csv += "\(time),"
            csv += "\(qso.band),"
            csv += "\(qso.mode),"
            csv += "\(qso.rstSent),"
            csv += "\(qso.rstRcvd),"
            csv += "\(qso.txPwr),"
            csv += "\(qso.country),"
            csv += "\(qso.province),"
            csv += "\(qso.city),"
            csv += "\(qso.address),"
            csv += "\(qso.cqZone),"
            csv += "\(qso.ituZone),"
            csv += "\(qso.gridLocator),"
            csv += "\(qso.repeaterName),"
            csv += "\(qso.qslSent.displayName),"
            csv += "\(qso.qslRcvd.displayName),"
            csv += "\"\(qso.comment)\"\n"
        }
        
        return csv
    }
}

enum ADIFError: Error {
    case invalidFormat
    case fileNotFound
    case parseError
}
