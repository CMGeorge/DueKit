//
//  ReminderSettings.swift
//  DueKit
//
//  Created by Calugar George on 18/09/2026.
//

public struct ReminderSettings:Sendable, Hashable {
    public let isEnabled: Bool
    public let daysBefore: Int
    public let hour: Int
    public let minute: Int
    
    public static let allowedDaysBefore = 0...30
    
    public init(isEnabled: Bool = true, daysBefore: Int = 1, hour: Int = 10 , minute: Int = 0) throws (ReminderSettingsError){
        
        guard Self.allowedDaysBefore.contains(daysBefore) else {
            throw .daysBeforeOutOfRange(daysBefore)
        }
        guard (0..<24).contains(hour) else {
            throw .hourOutOfRange(hour)
        }
        guard (0..<60).contains(minute) else {
            throw .minuteOutOfRange(minute)
        }
        self.isEnabled = isEnabled
        self.daysBefore = daysBefore
        self.hour = hour
        self.minute = minute
    }
}
// MARK: - Codable
extension ReminderSettings: Codable {
    private enum CodingKeys: CodingKey { case isEnabled, daysBefore, hour, minute }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(isEnabled: container.decode(Bool.self, forKey: .isEnabled),
                      daysBefore: container.decode(Int.self, forKey: .daysBefore),
                      hour: container.decode(Int.self, forKey: .hour),
                      minute: container.decode(Int.self, forKey: .minute))
    }
}
