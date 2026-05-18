struct ErrorPayload: Codable {
    let code: String
    let message: String
    let detail: String?
}
