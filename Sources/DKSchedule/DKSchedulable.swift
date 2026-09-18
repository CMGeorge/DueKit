//
//  DKSchedulable.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation

public protocol Schedulable: Identifiable, Sendable where ID == UUID {
    var nextDueDate: Date { get }
    var rule: RecurrenceRule { get }
    var isReminderEnable: Bool { get }
}
