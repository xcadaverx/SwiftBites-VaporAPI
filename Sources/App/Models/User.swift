import Vapor
import FluentPostgreSQL
import Authentication

// MARK: User

final class User: Codable {
    
    var id: UUID?
    
    var name: String
    var username: String
    var password: String
    
    init(name: String, username: String, password: String) {
        
        self.name = name
        self.username = username
        self.password = password
    }
    
    
    // MARK: Public User
    final class Public: Codable, PostgreSQLUUIDModel, Parameter, Content {
        
        var id: UUID?
        
        var name: String
        var username: String
        
        init(name: String, username: String) {
            
            self.name = name
            self.username = username
        }
        
        static let entity = User.entity
    }
}

// MARK: Relationships

extension User {
    
    var bites: Children<User, Bite> {
    
        return children(\.authorID)
    }
}

extension User: Content {}
extension User: PostgreSQLUUIDModel {}
extension User: Migration {}
extension User: Parameter {}

// MARK: Authentication

extension User: BasicAuthenticatable {
 
    static var usernameKey: UsernameKey = \User.username
    static var passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    
    typealias TokenType = Token
}

extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}
