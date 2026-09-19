//
//  Calendar+DueKit.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

import Foundation

extension Calendar { //for testing
    public static func dueKit(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
