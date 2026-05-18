struct NotificationRecord: Codable {
    let id: String
    let state: String
    let title: String
    let subtitle: String
    let message: String
    let level: NotificationLevel?
    let group: String?
}

struct NotificationListData: Codable {
    let delivered: [NotificationRecord]
    let pending: [NotificationRecord]
}
