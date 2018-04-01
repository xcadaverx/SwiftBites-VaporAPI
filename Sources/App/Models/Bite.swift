import Vapor
import FluentPostgreSQL

final class Bite: Codable {

    var id: Int?
    
    var title: String
    var description: String
    var authorID: User.ID
    
    init(title: String, description: String, authorID: User.ID) {
        
        self.title = title
        self.description = description
        self.authorID = authorID
    }
}

extension Bite {
    
    var author: Parent<Bite, User> {
        
        return parent(\.authorID)
    }
    
    var tags: Siblings<Bite, Tag, BiteTagPivot> {
        
        return siblings()
    }
}

extension Bite: PostgreSQLModel {}
extension Bite: Parameter {}
extension Bite: Content {}
extension Bite: Migration {}
