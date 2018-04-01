import Vapor
import Authentication
import Crypto
import FluentSQL

final class UsersController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let usersRoutes = router.grouped("api", "users")

        usersRoutes.get(use: getAllUsersHandler)
        usersRoutes.get(User.Public.parameter, use: getUserHandler)
        usersRoutes.post(use: createUserHandler)
        usersRoutes.get(User.parameter, "bites", use: getBitesHandler)

        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    func getAllUsersHandler(_ req: Request) throws -> Future<[User.Public]> {
        
        return User.Public.query(on: req).all()
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        
        return try req.parameter(User.Public.self)
    }
    
    func createUserHandler(_ req: Request) throws -> Future<User> {
        
        return try req.content.decode(User.self).flatMap(to: User.self) { user in
            
            return try User.query(on: req).filter(\User.username == user.username).first().flatMap(to: User.self) { existingUser in
             
                guard existingUser == nil else {
                    throw Abort(.conflict, reason: "User Already Exists.")
                }
                
                user.password = try String.convertFromData(BCrypt.hash(user.password, cost: 4))
                
                return user.save(on: req)
            }
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        
        return token.save(on: req)
    }
    
    func getBitesHandler(_ req: Request) throws -> Future<[Bite]> {
        
        return try req.parameter(User.self).flatMap(to: [Bite].self) { user in
            
            return try user.bites.query(on: req).all()
        }
    }
}
