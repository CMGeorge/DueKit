//
//  RemindersTests.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

import DKReminders
import DKSchedule
import Foundation
import Testing

private let calendar = Calendar.dueKit(timeZone: TimeZone(identifier: "Europe/Bucharest")!)

private func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, in calendar: Calendar = calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

/// A minimal item. DueKit knows nothing about the app's own types.
private struct Item: Schedulable {
    let id = UUID()
    let nextDueDate: Date
    let rule = try! RecurrenceRule(monthlyEvery: 1, on: 15)
    var isReminderEnabled = true
}

private func text(_: Item) -> ReminderData { ReminderData(title: "Due", body: "Something is due") }

private func fireParts(_ reminder: Reminder) -> [Int?] {
    let c = reminder.fireComponent
    return [c.year, c.month, c.day, c.hour, c.minute]
}

@Suite("Settings")
struct SettingsTests {
    @Test("Defaults: on, 1 day before, at 10:00")
    func defaults() throws {
        let settings = try ReminderSettings()
        #expect(settings.isEnabled)
        #expect(settings.daysBefore == 1)
        #expect(settings.hour == 10)
        #expect(settings.minute == 0)
    }

    @Test("Invalid values are rejected", arguments: [
        ((-1, 9, 0), ReminderSettingsError.daysBeforeOutOfRange(-1)),
        ((31, 9, 0), .daysBeforeOutOfRange(31)),
        ((1, 24, 0), .hourOutOfRange(24)),
        ((1, -1, 0), .hourOutOfRange(-1)),
        ((1, 9, 60), .minuteOutOfRange(60)),
    ])
    func invalid(values: (Int, Int, Int), expected: ReminderSettingsError) {
        #expect(throws: expected) {
            try ReminderSettings(daysBefore: values.0, hour: values.1, minute: values.2)
        }
    }

    @Test("Round-trips through Codable, and bad stored data is rejected")
    func codable() throws {
        let settings = try ReminderSettings(isEnabled: false, daysBefore: 3, hour: 18, minute: 30)
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(ReminderSettings.self, from: data) == settings)

        let bad = #"{"isEnabled":true,"daysBefore":99,"hour":9,"minute":0}"#
        #expect(throws: (any Error).self) { try JSONDecoder().decode(ReminderSettings.self, from: Data(bad.utf8)) }
    }
}

@Suite("Planning")
struct PlanningTests {
    let now = at(2026, 9, 19, 12)

    @Test("Fires the chosen number of days before, at the chosen time")
    func fireTime() throws {
        let planner = Planner(settings: try ReminderSettings(daysBefore: 3, hour: 18, minute: 30))
        let item = Item(nextDueDate: at(2026, 10, 15))
        let plan = planner.add(for: [item], now: now, in: calendar, content: text)
        #expect(plan.count == 1)
        #expect(fireParts(plan[0]) == [2026, 10, 12, 18, 30])
        #expect(plan[0].id == planner.identifierPrefix + item.id.uuidString)
        #expect(plan[0].uuid == item.id)
        #expect(plan[0].content.title == "Due")
    }

    @Test("0 days before fires on the due day")
    func sameDay() throws {
        let planner = Planner(settings: try ReminderSettings(daysBefore: 0, hour: 9))
        let plan = planner.add(for: [Item(nextDueDate: at(2026, 10, 15))], now: now, in: calendar, content: text)
        #expect(fireParts(plan[0]) == [2026, 10, 15, 9, 0])
    }

    @Test("The due date's time of day doesn't move the reminder")
    func dueTimeIgnored() throws {
        let planner = Planner(settings: try ReminderSettings(daysBefore: 1, hour: 9))
        let plan = planner.add(for: [Item(nextDueDate: at(2026, 10, 15, 23, 45))], now: now, in: calendar, content: text)
        #expect(fireParts(plan[0]) == [2026, 10, 14, 9, 0])
    }

    @Test("Nothing is planned when reminders are off")
    func disabledInSettings() throws {
        let planner = Planner(settings: try ReminderSettings(isEnabled: false))
        #expect(planner.add(for: [Item(nextDueDate: at(2026, 10, 15))], now: now, in: calendar, content: text).isEmpty)
    }

    @Test("Items with their reminder switched off are skipped")
    func disabledOnItem() throws {
        let planner = Planner(settings: try ReminderSettings())
        let off = Item(nextDueDate: at(2026, 10, 15), isReminderEnabled: false)
        let on = Item(nextDueDate: at(2026, 10, 16))
        let plan = planner.add(for: [off, on], now: now, in: calendar, content: text)
        #expect(plan.map(\.uuid) == [on.id])
    }

    @Test("Reminders whose moment has passed are skipped", arguments: [
        ((2026, 9, 20), false),  // fires 19 Sep 09:00, before now (12:00)
        ((2026, 9, 21), true),   // fires 20 Sep 09:00
        ((2026, 9, 1), false),   // overdue item
    ])
    func past(due: (Int, Int, Int), planned: Bool) throws {
        let planner = Planner(settings: try ReminderSettings(daysBefore: 1, hour: 9))
        let plan = planner.add(for: [Item(nextDueDate: at(due.0, due.1, due.2))], now: now, in: calendar, content: text)
        #expect(plan.isEmpty != planned)
    }

    @Test("Keeps only the nearest maximumPending, in firing order")
    func limit() throws {
        let planner = Planner(settings: try ReminderSettings(daysBefore: 0, hour: 9))
        let start = at(2026, 9, 20)
        let items = (1...100).reversed().map { Item(nextDueDate: calendar.date(byAdding: .day, value: $0, to: start)!) }
        let plan = planner.add(for: items, now: now, in: calendar, content: text)
        #expect(plan.count == Planner.maximumPending)
        #expect(plan.map(\.onDate) == plan.map(\.onDate).sorted())
        #expect(fireParts(plan.first!) == [2026, 9, 21, 9, 0])
        let lastDay = calendar.date(byAdding: .day, value: Planner.maximumPending, to: start)!
        let last = calendar.dateComponents([.year, .month, .day], from: lastDay)
        #expect(fireParts(plan.last!) == [last.year, last.month, last.day, 9, 0])
    }

    @Test("A custom prefix is used for identifiers")
    func prefix() throws {
        let planner = Planner(settings: try ReminderSettings(), identifierPrefix: "app.")
        let item = Item(nextDueDate: at(2026, 10, 15))
        #expect(planner.add(for: [item], now: now, in: calendar, content: text).first?.id == "app." + item.id.uuidString)
    }
}

@Suite("Clock changes")
struct ReminderClockChangeTests {
    @Test("Wall-clock time is kept across clock changes", arguments: [
        ((2026, 3, 30), [2026, 3, 29, 9, 0]),    // Bucharest: clocks go forward on 29 Mar
        ((2026, 10, 26), [2026, 10, 25, 9, 0]),  // Bucharest: clocks go back on 25 Oct
    ])
    func bucharest(due: (Int, Int, Int), expected: [Int]) throws {
        let planner = Planner(settings: try ReminderSettings(daysBefore: 1, hour: 9))
        let plan = planner.add(for: [Item(nextDueDate: at(due.0, due.1, due.2))], now: at(2026, 1, 1), in: calendar, content: text)
        #expect(fireParts(plan[0]).compactMap { $0 } == expected)
        #expect(calendar.component(.hour, from: plan[0].onDate) == 9)
    }

    @Test("A reminder at midnight on a day without midnight (Chile) still fires that day")
    func santiagoMidnight() throws {
        let santiago = Calendar.dueKit(timeZone: TimeZone(identifier: "America/Santiago")!)
        let planner = Planner(settings: try ReminderSettings(daysBefore: 0, hour: 0))
        let plan = planner.add(for: [Item(nextDueDate: at(2026, 9, 6, in: santiago))], now: at(2026, 9, 1, in: santiago), in: santiago, content: text)
        #expect(plan.count == 1)
        #expect(santiago.component(.day, from: plan[0].onDate) == 6)
    }
}

/// Stands in for the system, so apps can test that they call `replaceAll`.
private actor RecordingScheduler: ReminderScheduler {
    private(set) var batches: [[Reminder]] = []
    func replaceAll(with reminders: [Reminder]) async throws { batches.append(reminders) }
}

@Suite("Scheduling contract")
struct SchedulingTests {
    @Test("A plan can be handed to any scheduler")
    func handOff() async throws {
        let scheduler = RecordingScheduler()
        let planner = Planner(settings: try ReminderSettings())
        let plan = planner.add(for: [Item(nextDueDate: at(2026, 10, 15))], now: at(2026, 9, 19), in: calendar, content: text)
        try await scheduler.replaceAll(with: plan)
        #expect(await scheduler.batches == [plan])
    }
}
