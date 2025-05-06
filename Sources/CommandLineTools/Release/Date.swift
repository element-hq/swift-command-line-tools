import Foundation

extension Date {
    /// Formats the date do be used as a CalVar: https://calver.org
    /// For libraries we use the format `0Y.0W.0D` with a `-x` for the optional build number.
    public func calendarVersion(buildNumber: Int? = nil) -> String {
        let year = formatted(.dateTime.year(.twoDigits))
        let month = formatted(.dateTime.month(.twoDigits))
        let day = formatted(.dateTime.day(.twoDigits))
        
        let calVer = "\(year).\(month).\(day)"
        if let buildNumber {
            return calVer + "-\(buildNumber)"
        }
        return calVer
    }
}
