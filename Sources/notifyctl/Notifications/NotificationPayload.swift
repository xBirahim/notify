struct NotificationPayload: Codable {
    var id: String?
    var title: String?
    var subtitle: String?
    var body: String
    var sound: NotificationSound
    var thread: String?
    var category: String?
    var url: String?
    var userInfo: [String: String]
}
