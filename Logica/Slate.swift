import Foundation
import SwiftData


struct Discovery : Hashable, Codable {
    var text: String
    var emoji: String
    var creators: [String]
}

@Model
final class Slate {
    @Attribute(.unique) var id: UUID
    var foundDate: Date

    var placedX: Double
    var placedY: Double
    var hasPlacedLocation: Bool
    var text : String
    var emoji : String
    var creators: [String]
    
    init(discovery: Discovery, placedLocation: CGPoint) {
        self.id = UUID()
        self.foundDate = Date()
        self.placedX = placedLocation.x
        self.placedY = placedLocation.y
        self.hasPlacedLocation = true
        self.text = discovery.text
        self.emoji = discovery.emoji
        self.creators = discovery.creators
    }

    var location: CGPoint? {
        get { hasPlacedLocation ? CGPoint(x: placedX, y: placedY) : nil }
        set {
            if let p = newValue {
                placedX = p.x
                placedY = p.y
                hasPlacedLocation = true
            } else {
                hasPlacedLocation = false
            }
        }
    }
}
