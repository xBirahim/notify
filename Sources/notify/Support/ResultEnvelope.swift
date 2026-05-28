struct ResultEnvelope<T: Codable>: Codable {
    let id: String?
    let command: String
    let status: String
    let data: T?
    let error: ErrorPayload?
}
