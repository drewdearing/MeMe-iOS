//
//  Timestamp.swift
//  MeMe
//
//  Created by Drew Dearing on 4/23/19.
//  Copyright © 2019 meme. All rights reserved.
//

//timestamp class used for things such as ordering the placement of memes on home feed, making sure memes go away after a day
import Foundation
import Firebase

class Timestamp: Codable, Comparable {
    let _seconds:Int64
    let _nanoseconds:Int32
    
    init(s:Int64, n:Int32){
        self._seconds = s
        self._nanoseconds = n
    }
    
    init(s:Double){
        self._seconds = Int64(s)
        self._nanoseconds = Int32((s - Double(self._seconds)) * 1000000000)
    }
    
    func dateValue() -> Date {
        return firebaseTimestamp().dateValue()
    }
    
    func firebaseTimestamp() -> Firebase.Timestamp {
        return Firebase.Timestamp(seconds: self._seconds, nanoseconds: self._nanoseconds)
    }
    
    static func getServerTime(complete: @escaping (Timestamp?) -> Void) {
        let urlPathBase = "https://us-central1-meme-d3805.cloudfunctions.net/serverTimestamp"
        let request = NSMutableURLRequest()
        request.url = URL(string: urlPathBase)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, err) in
            guard let data = data else {
                DispatchQueue.main.async {
                    complete(nil)
                }
                return
            }
            do {
                let serverTime = try JSONDecoder().decode(Timestamp.self, from: data)
                DispatchQueue.main.async {
                    complete(serverTime)
                }
            } catch let jsonErr {
                DispatchQueue.main.async {
                    complete(nil)
                }
                print("Error: \(jsonErr)")
            }
        }
        task.resume()
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
