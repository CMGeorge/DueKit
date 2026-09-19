//
//  DKReminderError.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

public enum ReminderSettingsError: Error,Equatable {
    case daysBeforeOutOfRange(Int)
    case hourOutOfRange(Int)
    case minuteOutOfRange(Int)
}
