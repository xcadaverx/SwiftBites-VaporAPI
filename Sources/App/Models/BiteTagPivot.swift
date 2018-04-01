import FluentPostgreSQL
import Vapor

final class BiteTagPivot: PostgreSQLPivot {
    var id: Int?
    
    var biteID: Bite.ID
    var tagID: Tag.ID
    
    typealias Left = Bite
    typealias Right = Tag
    
    static let leftIDKey: LeftIDKey = \BiteTagPivot.biteID
    static let rightIDKey: RightIDKey = \BiteTagPivot.tagID
    
    init(_ biteID: Bite.ID, _ tagID: Tag.ID) {
        
        self.biteID = biteID
        self.tagID = tagID
    }
}

extension BiteTagPivot: Migration {}
