//
//  DueStatusPolicy.swift
//  DueKit
//
//  Created by Calugar George on 19/09/2026.
//

import Foundation

public struct DueStatusPolicy {
    // How many days ahead count as due soon. 0 = in the day
    public let dueInDaysNotification: Int

    // Allowed interval for dueInDaysNotification
    private static let dueInterval = 0...366

    public init(dueInDaysNotification: Int = 7) throws (DueStatusError) {
        guard Self.dueInterval.contains(dueInDaysNotification) else {
            throw .dueSoonDaysOutOfRange(dueInDaysNotification)
        }
        self.dueInDaysNotification = dueInDaysNotification
    }
    public func status(of dueDate: Date, now: Date, in calendar: Calendar )  -> DueStatus {
        let daysUntil = DueStatusPolicy.daysUntil(dueDate: dueDate, from: now, in: calendar)
        if daysUntil < 0 {
            return .overdue
        }
        if daysUntil <= dueInDaysNotification {
            return .dueSoon
        }
        return .upcoming
    }
    public static func daysUntil(dueDate: Date,from now: Date, in calendar: Calendar) -> Int { //need to be testable
        let today = calendar.dateComponents([.year, .month, .day], from: now)
        let due = calendar.dateComponents([.year, .month, .day], from: dueDate)
        
        var utcCalendar = Calendar(identifier: .gregorian)
        
        utcCalendar.timeZone = .gmt
        
        guard let todayInUTC = utcCalendar.date(from: today),
              let dueInUTC = utcCalendar.date(from: due),
              let days = utcCalendar.dateComponents([.day], from: todayInUTC, to: dueInUTC).day
                else {
            return 0
        }
        return days
    }
}

