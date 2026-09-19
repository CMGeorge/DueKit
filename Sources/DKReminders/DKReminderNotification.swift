//
//  DKReminderNotification.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

import UserNotifications


//TODO: should be tested.
public struct ReminderNotification: ReminderScheduler, ReminderAuthorizing{
    public let identifierPrefix: String
    
    public init(identifierPrefix: String = "ro.wesell.duekit.reminder.") {
            self.identifierPrefix = identifierPrefix
    }
    
    public func replaceAll(with reminders: [Reminder]) async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        let pendingNotifications = await notificationCenter.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: pendingNotifications)

        for reminder in reminders {
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = reminder.content.title
            notificationContent.body = reminder.content.body
            //TODO: Add the custom data
            notificationContent.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.fireComponent, repeats: false)
            try await notificationCenter.add(UNNotificationRequest(identifier: reminder.id, content: notificationContent, trigger: trigger))
        }
    }
    
    public func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }
    public func isAuthorized() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                return status == .authorized || status == .provisional
    }
}
