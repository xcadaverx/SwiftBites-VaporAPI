import Vapor
import FluentSQL
import Authentication

final class BitesController: RouteCollection {
    
    // Mark: Register Routes
    
    func boot(router: Router) throws {
        
        let bitesGroup = router.grouped("api", "bites")
        
        bitesGroup.get(use: getAllBitesHandler)
        bitesGroup.get(Bite.parameter, use: getBiteHandler)
        bitesGroup.get(Bite.parameter, "tags", use: getBiteTagsHandler)
        bitesGroup.get("search", use: searchBitesHandler)
        
        // Requires Authentication
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let tokenAuthGroup = bitesGroup.grouped(tokenAuthMiddleware)
        
        tokenAuthGroup.post(use: createBiteHandler)
        tokenAuthGroup.delete(Bite.parameter, use: deleteBiteHandler)
    }
    
    // MARK: Get Bites
    
    func getBiteHandler(_ req: Request) throws -> Future<Bite> {

        return try req.parameters.next(Bite.self)
    }
    
    func getAllBitesHandler(_ req: Request) throws -> Future<[Bite]> {

        return Bite.query(on: req).all()
    }
    
    // MARK: Create Bites
    
    func createBiteHandler(_ req: Request) throws -> Future<Bite> {
        
        // decode the incoming request of an array of bites
        return try req.content.decode(BiteCreationData.self).flatMap(to: Bite.self) { biteCreationData -> Future<Bite> in
            
            // ensure an authenticated user
            let user = try req.requireAuthenticated(User.self)

            // create a new bite
            let bite = try Bite(title: biteCreationData.title, description: biteCreationData.description, authorID: user.requireID())
            
            // determine which tags already exist in the database
            let existingTagsFuture = Tag.query(on: req).filter(\Tag.title ~~ biteCreationData.tags).all()
            
            return flatMap(to: Bite.self, bite.create(on: req), existingTagsFuture) { createdBite, existingTags -> Future<Bite> in
            
                // determine which tags need to be created still
                let newTagsFuture = biteCreationData.tags.reduce(into: [Future<Tag>]()) { createdTags, tagString in
                    if !existingTags.contains(where: { $0.title == tagString}) {
                        createdTags.append(Tag(title: tagString).save(on: req))
                    }
                }
                
                // create a pivot for each of the existing tags
                let existingTagPivots = try existingTags.map { existingTag in
                    return try BiteTagPivot(createdBite.requireID(), existingTag.requireID()).save(on: req)
                }
                
                return flatMap(to: Bite.self, newTagsFuture.flatten(on: req), existingTagPivots.flatten(on: req)) { newTags, existingTagPivots in
                    
                    // create pivot for each of the new tags
                    return try newTags
                        .map { try BiteTagPivot(createdBite.requireID(), $0.requireID()).save(on: req) }
                        .flatten(on: req)
                        .transform(to: createdBite) // return the created bite
                }
            }
        }
    }
    
    // MARK: Delete Bites
    
    func deleteBiteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        
        return try req.parameters.next(Bite.self).flatMap(to: HTTPStatus.self) { bite in
            
            let userID = try req.requireAuthenticated(User.self).requireID()
            
            guard bite.authorID == userID else {
                throw Abort(.badRequest, reason: "User does not have permission to delete this Bite.")
            }
            
            return bite.tags
                .detachAll(on: req)
                .and(bite.delete(on: req))
                .transform(to: HTTPStatus.noContent)
        }
    }
    
    // MARK: Search Bites
    
    func searchBitesHandler(_ req: Request) throws -> Future<[Bite]> {
        
        guard let searchQuery = req.query[String.self, at: "keywords"] else {
            throw Abort(.badRequest, reason: "Missing keywords parameter in request.")
        }
        
        let separators = CharacterSet(charactersIn: ", ")
        let terms = searchQuery.components(separatedBy: separators)
        
        return Bite.query(on: req).group(.or) { or in
            terms.forEach { term in
                or.filter(\Bite.title ~~ term)
                or.filter(\Bite.description ~~ term)
                // try or.filter(\Bite.tags ~~ term) // Bite.tags is a Siblings<Bite, Tag, BiteTagPivot>
            }
        }.all()
    }
    
    // MARK: Bite Tags
    
    func getBiteTagsHandler(_ req: Request) throws -> Future<[Tag]> {
        
        return try req.parameters.next(Bite.self).flatMap(to: [Tag].self) { bite in
            
            return try bite.tags.query(on: req).all()
        }
    }
}


struct BiteCreationData: Content {
    
    let title: String
    let description: String
    let tags: [String]
}
