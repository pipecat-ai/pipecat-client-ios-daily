import Foundation

struct DailyTransportAuthBundle: Decodable {
    let roomUrl: String
    let token: String?
    
    enum CodingKeys: String, CodingKey {
        case roomUrl = "room_url"
        case roomUrlAlt1 = "url"
        case roomUrlAlt2 = "dailyRoom"
        case token
        case tokenAlt = "dailyToken"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode roomUrl from any of the possible keys
        if let roomUrl = try? container.decode(String.self, forKey: .roomUrl) {
            self.roomUrl = roomUrl
        } else if let roomUrl = try? container.decode(String.self, forKey: .roomUrlAlt1) {
            self.roomUrl = roomUrl
        } else if let roomUrl = try? container.decode(String.self, forKey: .roomUrlAlt2) {
            self.roomUrl = roomUrl
        } else {
            throw DecodingError.keyNotFound(CodingKeys.roomUrl, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "No valid key found for roomUrl among: room_url, url, dailyRoom"
            ))
        }
        
        // Try to decode token from either key
        if let token = try? container.decode(String.self, forKey: .token) {
            self.token = token
        } else if let token = try? container.decode(String.self, forKey: .tokenAlt) {
            self.token = token
        } else {
            throw DecodingError.keyNotFound(CodingKeys.roomUrl, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "No valid key found for token among: token, dailyToken"
            ))
        }
    }
}
