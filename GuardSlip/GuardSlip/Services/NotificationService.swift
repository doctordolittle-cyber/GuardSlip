import Foundation
import UserNotifications

// MARK: - Protocol

protocol NotificationServiceProtocol {
    func requestPermission() async -> Bool
    func scheduleNotifications(for item: WarrantyItem)
    func cancelNotifications(for itemID: UUID)
}

// MARK: - Implementation

final class NotificationService: NotificationServiceProtocol {
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    // MARK: - Scheduling
    
    func scheduleNotifications(for item: WarrantyItem) {
        cancelNotifications(for: item.id)
        
        for offset in item.reminderOffsets {
            let triggerDate = Calendar.current.date(byAdding: .day, value: -offset, to: item.expiryDate)
            guard let triggerDate, triggerDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Warranty Reminder"
            content.body = "⚠️ \(item.name) warranty expires in \(offset) days. Check your receipt while you still can!"
            content.sound = .default
            content.categoryIdentifier = "WARRANTY_REMINDER"
            content.userInfo = ["itemID": item.id.uuidString]
            
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = "\(item.id.uuidString)_\(offset)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request)
        }
    }
    
    // MARK: - Cancellation
    
    func cancelNotifications(for itemID: UUID) {
        let prefix = itemID.uuidString
        center.getPendingNotificationRequests { [weak self] requests in
            let matching = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            self?.center.removePendingNotificationRequests(withIdentifiers: matching)
        }
    }
}
