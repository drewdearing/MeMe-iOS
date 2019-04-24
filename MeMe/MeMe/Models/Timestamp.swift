//
//  Timestamp.swift
//  MeMe
//
//  Created by Drew Dearing on 4/23/19.
//  Copyright © 2019 meme. All rights reserved.
//

import Foundation

class Timestamp: Codable, Comparable {
    let _seconds:Int64
    let _nanoseconds:Int32
    
    init(){
        let currentTime = NSDate().timeIntervalSince1970
        self._seconds = Int64(currentTime)
        self._nanoseconds = Int32((currentTime - Double(self._seconds)) * 1000000000)
    }
    
    init(s:Int64, n:Int32){
        self._seconds = s
        self._nanoseconds = n
    }
    
    init(s:Double){
        self._seconds = Int64(s)
        self._nanoseconds = Int32((s - Double(self._seconds)) * 1000000000)
    }
    
    static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        if lhs._seconds == rhs._seconds {
            return lhs._nanoseconds < rhs._nanoseconds
        }
        return lhs._seconds < rhs._seconds
    }
    
    static func == (lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs._seconds == rhs._seconds && lhs._nanoseconds == rhs._nanoseconds
    }
}
