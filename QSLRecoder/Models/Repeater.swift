import Foundation
import SwiftData

@Model
final class Repeater {
    var id: UUID
    var name: String
    var callsign: String
    var uplinkFreq: Double
    var downlinkFreq: Double
    var offsetFreq: Double
    var band: String
    var mode: String
    var ctcssTx: Double
    var ctcssRx: Double
    var location: String
    var city: String
    var province: String
    var latitude: Double
    var longitude: Double
    var comment: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        callsign: String = "",
        uplinkFreq: Double = 0.0,
        downlinkFreq: Double = 0.0,
        offsetFreq: Double = 0.0,
        band: String = "",
        mode: String = "FM",
        ctcssTx: Double = 88.5,
        ctcssRx: Double = 88.5,
        location: String = "",
        city: String = "",
        province: String = "",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        comment: String = "",
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.callsign = callsign
        self.uplinkFreq = uplinkFreq
        self.downlinkFreq = downlinkFreq
        self.offsetFreq = offsetFreq
        self.band = band
        self.mode = mode
        self.ctcssTx = ctcssTx
        self.ctcssRx = ctcssRx
        self.location = location
        self.city = city
        self.province = province
        self.latitude = latitude
        self.longitude = longitude
        self.comment = comment
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}