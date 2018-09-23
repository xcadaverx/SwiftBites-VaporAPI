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
        
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        
        authSessionRoutes.get(use: index)
        authSessionRoutes.get("login", use: login)
        authSessionRoutes.post("login", use: loginPostHandler)
    }
    
    private func index(_ req: Request) throws -> Future<View> {
        
        let user = try req.authenticated(User.self)
        
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
                let bitesContext = BitesContext(user: user, bites: biteContexts)
                return try req.view().render("index", bitesContext)
            }
        }
    }
    
    private func login(_ req: Request) throws -> Future<View> {
        
        let user = try req.authenticated(User.self)
        
        if user != nil {
            return try self.index(req)
        } else {
            return try req.view().render("login")
        }
    }
    
    private func loginPostHandler(_ req: Request) throws -> Future<Response> {
        
        return try req.content
            .decode(LoginPostData.self)
            .flatMap(to: Response.self) { data in
                let verify = try req.make(BCryptDigest.self)
                return User.authenticate(username: data.username, password: data.password, using: verify, on: req).map(to: Response.self) { user in
                    guard let user = user else {
                        return req.redirect(to: "/login")
                    }
                    try req.authenticateSession(user)
                    return req.redirect(to: "/")
                }
        }
    }
}

struct LoginPostData: Content {

    let username: String
    let password: String
}

struct BitesContext: Encodable {

    let user: User?
    let bites: [BiteContext]
}

struct BiteContext: Content {
    
    let title: String
    let description: String
    let authorUsername: String
    let tags: [Tag]
}

