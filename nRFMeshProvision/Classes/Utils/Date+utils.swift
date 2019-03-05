//
//  Data+utils.swift
//  nRFMeshProvision
//
//  Created by Mostafa Berg on 22/12/2017.
//

import Foundation

public extension Date {
    
    public init?(hexString: String) {
        let dateData = Data(hexString: hexString.uppercased());
        let seconds = Double(dateData?.uint64BigEndian ?? 0);
        var datecomponents = DateComponents();
        datecomponents.year = 2000;
        datecomponents.month = 1;
        datecomponents.day = 1;
        let gregorianCalendar = Calendar(identifier: .gregorian)
        let refDate = gregorianCalendar.date(from: datecomponents)
        
        if let date = refDate?.addingTimeInterval(TimeInterval(seconds)) {
            self = date;
        } else {
            return nil;
        }
    }
    
    public func hexString() -> String {
        var datecomponents = DateComponents();
        datecomponents.year = 2000;
        datecomponents.month = 1;
        datecomponents.day = 1;
        let gregorianCalendar = Calendar(identifier: .gregorian)
        if let refDate = gregorianCalendar.date(from: datecomponents) {
            
            let persicionSeconds = Date().timeIntervalSince(refDate);
            let seconds = UInt64(round(persicionSeconds))
            let dataDate = Data(fromInt64: seconds)
            return dataDate.hexString().lowercased();
        }
        return "";
   }
}
