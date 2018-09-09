//
//  WebController.swift
//  App
//
//  Created by Daniel Williams on 9/8/18.
//

import Foundation
import Vapor
import Leaf
import Authentication

class WebController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let webGroup = router.grouped("web")

        webGroup.get(use: index)
    }
    
    private func index(_ req: Request) throws -> Future<View> {
        
        return Bite.query(on: req).all().flatMap(to: View.self) { bites in
            
            let futureBitesContext = try bites.map { bite -> EventLoopFuture<BiteContext> in
                let futureTags = try bite.tags.query(on: req).all()
                let futureAuthor = bite.author.get(on: req)
                
                return flatMap(to: BiteContext.self, futureTags, futureAuthor) { tags, author in
                    return Future.map(on: req) {
                        return BiteContext(title: bite.title, description: bite.description, authorUsername: author.name, tags: tags)
                    }
                }
            }
            
            return futureBitesContext.flatten(on: req).flatMap(to: View.self) { biteContexts in
                let bitesContext = BitesContext(bites: biteContexts)
                return try req.view().render("index", bitesContext)
            }
        }
    }
}



struct BitesContext: Encodable {
    
    let bites: [BiteContext]
}

struct BiteContext: Content {
    
    let title: String
    let description: String
    let authorUsername: String
    let tags: [Tag]
}

