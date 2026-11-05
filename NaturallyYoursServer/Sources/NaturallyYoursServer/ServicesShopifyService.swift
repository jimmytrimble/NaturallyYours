import Vapor

/// Configuration for the Shopify Admin API (loaded from env; see `.env`).
/// - `SHOPIFY_STORE_DOMAIN`  e.g. "naturallyyourssupply.myshopify.com"
/// - `SHOPIFY_ADMIN_TOKEN`   the custom-app Admin API access token (shpat_…)
struct ShopifyConfiguration: Sendable {
    let storeDomain: String
    let adminToken: String
    let apiVersion: String

    static func fromEnvironment() -> ShopifyConfiguration? {
        guard
            let domain = Environment.get("SHOPIFY_STORE_DOMAIN"), !domain.isEmpty,
            let token = Environment.get("SHOPIFY_ADMIN_TOKEN"), !token.isEmpty
        else { return nil }
        let version = Environment.get("SHOPIFY_API_VERSION") ?? "2025-10"
        return ShopifyConfiguration(storeDomain: domain, adminToken: token, apiVersion: version)
    }

    var graphQLURL: String {
        "https://\(storeDomain)/admin/api/\(apiVersion)/graphql.json"
    }
}

/// A product pulled from Shopify (default variant only — the common case here).
struct ShopifyProduct: Content {
    let productID: String
    let variantID: String
    let inventoryItemID: String
    let title: String
    let descriptionHtml: String
    let status: String          // ACTIVE | DRAFT | ARCHIVED
    let productType: String
    let tags: [String]
    let sku: String?
    let price: Double
    let inventoryQuantity: Int
    let imageURLs: [String]
}

/// Thin wrapper over the Shopify Admin GraphQL API using Vapor's HTTP client.
///
/// NOTE: written against Admin API 2024-10. Not yet exercised against the live store
/// — verify once `SHOPIFY_*` env vars are set, then we can harden any field/mutation
/// mismatches. All callers treat failures as best-effort so local admin never breaks.
struct ShopifyService: Sendable {
    let config: ShopifyConfiguration
    let client: any Client
    let logger: Logger

    // MARK: - Core request

    private func graphQL(_ query: String, variables: [String: Any] = [:]) async throws -> ByteBuffer {
        let uri = URI(string: config.graphQLURL)
        var headers = HTTPHeaders()
        headers.add(name: "X-Shopify-Access-Token", value: config.adminToken)
        headers.contentType = .json

        // Encode body manually to allow arbitrary JSON variables.
        var body: [String: Any] = ["query": query]
        if !variables.isEmpty { body["variables"] = variables }
        let data = try JSONSerialization.data(withJSONObject: body)

        let response = try await client.post(uri, headers: headers) { req in
            req.body = .init(data: data)
        }
        guard response.status == .ok, let buffer = response.body else {
            throw Abort(.badGateway, reason: "Shopify API error (HTTP \(response.status.code))")
        }
        return buffer
    }

    private func json(_ buffer: ByteBuffer) throws -> [String: Any] {
        let data = Data(buffer: buffer)
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Abort(.badGateway, reason: "Shopify returned an unexpected response")
        }
        if let errors = obj["errors"] as? [[String: Any]], !errors.isEmpty {
            let msg = errors.compactMap { $0["message"] as? String }.joined(separator: "; ")
            throw Abort(.badGateway, reason: "Shopify GraphQL error: \(msg)")
        }
        return (obj["data"] as? [String: Any]) ?? [:]
    }

    // MARK: - Reads

    /// The store's primary location GID (needed for inventory writes).
    func primaryLocationID() async throws -> String {
        let data = try json(try await graphQL("{ location: locations(first: 1) { nodes { id } } }"))
        let nodes = ((data["location"] as? [String: Any])?["nodes"] as? [[String: Any]]) ?? []
        guard let id = nodes.first?["id"] as? String else {
            throw Abort(.badGateway, reason: "No Shopify location found")
        }
        return id
    }

    /// Fetches up to `limit` products with their default variant + inventory.
    func fetchProducts(limit: Int = 100) async throws -> [ShopifyProduct] {
        let query = """
        query($n: Int!) {
          products(first: $n) {
            nodes {
              id title descriptionHtml status productType tags
              featuredImage { url }
              images(first: 5) { nodes { url } }
              variants(first: 1) {
                nodes { id sku price inventoryQuantity inventoryItem { id } }
              }
            }
          }
        }
        """
        let data = try json(try await graphQL(query, variables: ["n": limit]))
        let nodes = ((data["products"] as? [String: Any])?["nodes"] as? [[String: Any]]) ?? []
        return nodes.compactMap { node in
            guard
                let productID = node["id"] as? String,
                let variant = ((node["variants"] as? [String: Any])?["nodes"] as? [[String: Any]])?.first,
                let variantID = variant["id"] as? String,
                let invItem = (variant["inventoryItem"] as? [String: Any])?["id"] as? String
            else { return nil }
            let images = ((node["images"] as? [String: Any])?["nodes"] as? [[String: Any]])?
                .compactMap { $0["url"] as? String } ?? []
            let priceStr = variant["price"] as? String ?? "0"
            return ShopifyProduct(
                productID: productID,
                variantID: variantID,
                inventoryItemID: invItem,
                title: node["title"] as? String ?? "",
                descriptionHtml: node["descriptionHtml"] as? String ?? "",
                status: node["status"] as? String ?? "ACTIVE",
                productType: node["productType"] as? String ?? "",
                tags: node["tags"] as? [String] ?? [],
                sku: variant["sku"] as? String,
                price: Double(priceStr) ?? 0,
                inventoryQuantity: variant["inventoryQuantity"] as? Int ?? 0,
                imageURLs: images
            )
        }
    }

    // MARK: - Writes

    /// Sets the on-hand quantity for a variant's inventory item at the given location.
    func setInventory(inventoryItemID: String, locationID: String, quantity: Int) async throws {
        let mutation = """
        mutation($input: InventorySetOnHandQuantitiesInput!) {
          inventorySetOnHandQuantities(input: $input) {
            userErrors { field message }
          }
        }
        """
        let variables: [String: Any] = [
            "input": [
                "reason": "correction",
                "setQuantities": [
                    ["inventoryItemId": inventoryItemID, "locationId": locationID, "quantity": quantity]
                ]
            ]
        ]
        _ = try json(try await graphQL(mutation, variables: variables))
    }

    /// Updates core product fields (title, description, status, tags).
    func updateProduct(productID: String, title: String, descriptionHtml: String, status: String, tags: [String]) async throws {
        let mutation = """
        mutation($input: ProductInput!) {
          productUpdate(input: $input) { userErrors { field message } }
        }
        """
        let variables: [String: Any] = [
            "input": ["id": productID, "title": title, "descriptionHtml": descriptionHtml, "status": status, "tags": tags]
        ]
        _ = try json(try await graphQL(mutation, variables: variables))
    }

    /// Updates a variant's price.
    func updateVariantPrice(productID: String, variantID: String, price: Double) async throws {
        let mutation = """
        mutation($pid: ID!, $variants: [ProductVariantsBulkInput!]!) {
          productVariantsBulkUpdate(productId: $pid, variants: $variants) {
            userErrors { field message }
          }
        }
        """
        let variables: [String: Any] = [
            "pid": productID,
            "variants": [["id": variantID, "price": String(format: "%.2f", price)]]
        ]
        _ = try json(try await graphQL(mutation, variables: variables))
    }

    /// Sets product status (ACTIVE to publish, DRAFT/ARCHIVED to hide).
    func setStatus(productID: String, status: String) async throws {
        let mutation = """
        mutation($input: ProductInput!) {
          productUpdate(input: $input) { userErrors { field message } }
        }
        """
        _ = try json(try await graphQL(mutation, variables: ["input": ["id": productID, "status": status]]))
    }
}
