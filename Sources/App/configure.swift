import FluentPostgreSQL
import Vapor
import Authentication

public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self) // Enables Sessions
    services.register(middlewares)

    // Configure PostgreSQL
    let dbConfig: PostgreSQLDatabaseConfig
    if env.isRelease {
        dbConfig = PostgreSQLDatabaseConfig(hostname: "localhost", port: 5432, username: "dawilliams", database: "postgres", password: nil)
    } else {
        dbConfig = PostgreSQLDatabaseConfig(hostname: "localhost", port: 5432, username: "dawilliams", database: "postgres", password: nil)
    }
    
    let postgresql = PostgreSQLDatabase(config: dbConfig)
    var databases = DatabaseConfig()
    databases.add(database: postgresql, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    
    migrations.add(model: Bite.self, database: .psql)
    migrations.add(model: Tag.self, database: .psql)
    migrations.add(model: BiteTagPivot.self, database: .psql)
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    
    User.Public.defaultDatabase = .psql
    
    services.register(migrations)
}
