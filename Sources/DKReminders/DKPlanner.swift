//
//  DKPlanner.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

import DKSchedule
import Foundation

public struct Planner: Sendable {
    public static let maximumPending = 50  // the number of scheduled items are limited to about 60. I let the rest for app. in the future maybe will be a option
    public let settings: ReminderSettings
    public let identifierPrefix: String
    
    public init(settings: ReminderSettings,
                identifierPrefix: String = "ro.wesell.duekit.reminder.") {
        self.settings = settings
        self.identifierPrefix = identifierPrefix
    }

    public func add<Item: Schedulable>(
        for items: [Item],
        now: Date,
        in calendar: Calendar,
        content: (Item) -> ReminderData
    ) -> [Reminder] {
        guard settings.isEnabled else {
            return []
        }
        let plannedItems = items.compactMap {
            item -> Reminder? in
            guard item.isReminderEnabled,
                let onDate = fireOnComponents(
                    for: item.nextDueDate,
                    in: calendar
                ),
                let fireDate = calendar.date(from: onDate),
                fireDate > now
            else {
                return nil
            }
            return Reminder(id: identifierPrefix+item.id.uuidString,
                            uuid: item.id,
                            content: content(item),
                            onDate: fireDate,
                            fireComponent: onDate)
        }
        return Array(plannedItems.sorted
                     { $0.onDate < $1.onDate }
            .prefix(Self.maximumPending))
    }
        
    private func fireOnComponents(for dueDate: Date, in calendard: Calendar)
        -> DateComponents?
    {
        guard
            let fierOn = calendard.date(
                from: calendard.dateComponents(
                    [.year, .month, .day],
                    from: dueDate
                )
            ),
            let reminderDay = calendard.date(
                byAdding: .day,
                value: -settings.daysBefore,
                to: fierOn
            )
        else {
            return nil
        }
        var components = calendard.dateComponents([.year,.month, .day], from: reminderDay)
        components.hour = settings.hour
        components.minute = settings.minute
        return components
    }
}
