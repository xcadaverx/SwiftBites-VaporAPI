import Routing
import Vapor

public func routes(_ router: Router) throws {
    
    // Register the Bites route collection
    let bitesController = BitesController()
    try router.register(collection: bitesController)
    
    // Register the Tags route collection
    let tagsController = TagsController()
    try router.register(collection: tagsController)
    
    // Register the Users route collection
    let usersController = UsersController()
    try router.register(collection: usersController)
}
