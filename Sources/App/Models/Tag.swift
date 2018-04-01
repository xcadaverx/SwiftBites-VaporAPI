import FluentPostgreSQL
import Vapor

final class Tag: Codable {
    
    var id: Int?
    var title: String
    
    init(title: String) {
        
        self.title = title
    }
}

extension Tag {
    
    var bites: Siblings<Tag, Bite, BiteTagPivot> {

        return siblings()
    }
}

extension Tag: PostgreSQLModel {}
extension Tag: Content {}
extension Tag: Migration {}
extension Tag: Parameter {}
