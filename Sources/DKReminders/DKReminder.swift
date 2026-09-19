//
//  DKReminder.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

import Foundation

public struct Reminder: Sendable, Hashable {
    public let id: String
    public let uuid: UUID
    public let content: ReminderData
    public let onDate: Date
    public let fireComponent: DateComponents
}
