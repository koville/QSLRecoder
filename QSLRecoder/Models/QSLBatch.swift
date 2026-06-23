import Foundation
import SwiftData

@Model
final class QSLBatch {
    var id: UUID
    var name: String
    var destination: String
    var via: BatchVia
    var sendDate: Date
    var status: BatchStatus
    var remark: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .nullify)
    var qsoRecords: [QSO]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        destination: String = "",
        via: BatchVia = .bureau,
        sendDate: Date = Date(),
        status: BatchStatus = .pending,
        remark: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        qsoRecords: [QSO] = []
    ) {
        self.id = id
        self.name = name
        self.destination = destination
        self.via = via
        self.sendDate = sendDate
        self.status = status
        self.remark = remark
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.qsoRecords = qsoRecords
    }
}

enum BatchVia: String, Codable, CaseIterable {
    case bureau = "Bureau"
    case direct = "Direct"
    case lotw = "LoTW"
    case eqsl = "eQSL"
}

enum BatchStatus: String, Codable, CaseIterable {
    case pending = "待发送"
    case sent = "已发送"
    case completed = "已完成"
}
