import Vapor
import FluentPostgreSQL
import FluentSQL

final class TagsController: RouteCollection {
    
    // MARK: Register Routes
    
    func boot(router: Router) throws {
        
        let tagsGroup = router.grouped("api", "tags")
        
        tagsGroup.get(use: getAllTagsHandler)
        tagsGroup.get(Tag.parameter, use: getTagByIDHandler)
        tagsGroup.get(Tag.parameter, "bites", use: getBitesForTagHandler)
        // tagsGroup.get(String.parameter, use: getTagByNameHandler) // ** Conflicts with getTagByIDHandler
        tagsGroup.get("search", use: searchTagsHandler)
    }
    
    // MARK: Get Tags
    
    func getAllTagsHandler(_ req: Request) throws -> Future<[Tag]> {
        
        return Tag.query(on: req).all()
    }
    
    func getTagByNameHandler(_ req: Request) throws -> Future<Tag> {

        let tagTitle = try req.parameters.next(String.self)
        let query = Tag.query(on: req).filter(\Tag.title == tagTitle)

        return query.first().map(to: Tag.self) { tag in

            guard let tag = tag else {
                throw Abort(.notFound, reason: "Could not find tag with title \(tagTitle).")
            }

            return tag
        }
    }
    
    func getTagByIDHandler(_ req: Request) throws -> Future<Tag> {
        
        return try req.parameters.next(Tag.self)
    }
    
    func getBitesForTagHandler(_ req: Request) throws -> Future<[Bite]> {
        
        return try req.parameters.next(Tag.self).flatMap(to: [Bite].self) { tag in
            
            return try tag.bites.query(on: req).all()
        }
    }
    
    // MARK: Search Tags
    
    func searchTagsHandler(_ req: Request) throws -> Future<[Tag]> {
        
        guard let searchQuery = req.query[String.self, at: "keywords"] else {
            throw Abort(.badRequest, reason: "Missing keywords parameter in request.")
        }
        
        let terms = searchQuery.components(separatedBy: " ")
        
        return Tag.query(on: req).group(.or) { or in
            terms.forEach { term in
                or.filter(\Tag.title ~~ term)
            }
        }.all()
    }
}
