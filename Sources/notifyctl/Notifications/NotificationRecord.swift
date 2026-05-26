struct NotificationRecord: Codable {
    let id: String
    let title: String
    let subtitle: String
    let body: String
    let category: String?
    let thread: String?
    let url: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, body, category, thread, url
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct NotificationListData: Codable {
    let delivered: [NotificationRecord]
    let pending: [NotificationRecord]
}
