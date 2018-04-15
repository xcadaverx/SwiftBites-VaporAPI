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
    if let dbURL = Environment.get("DATABASE_URL"), env.isRelease {
        dbConfig = try PostgreSQLDatabaseConfig(url: dbURL)
    } else {
        
        let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
        let port = Int(Environment.get("DATABASE_PORT")) ?? 5432
        let username = Environment.get("DATABASE_USERNAME") ?? "dawilliams"
        let database = Environment.get("DATABASE_DB") ?? "postgresql"
        let password = Environment.get("DATABASE_PASSWORD") ?? "password"
        
        dbConfig = PostgreSQLDatabaseConfig(hostname: hostname, port: port, username: username, database: database, password: password)
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

extension Int {
    
    init?(_ string: String?) {
        guard let stringValue = string else { return nil }
        guard let intValue = Int(stringValue) else { return nil }
        
        self = intValue
    }
}
