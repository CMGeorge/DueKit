//
//  DKReminderScheduler.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

public protocol ReminderScheduler: Sendable {
    func replaceAll(with reminders: [Reminder]) async throws
}

//permisions
public protocol ReminderAuthorizing: Sendable {
    func requestAuthorization() async throws -> Bool
    func isAuthorized() async -> Bool
}
