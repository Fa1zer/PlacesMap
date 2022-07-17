//
//  DataManager.swift
//  PlacesMap
//
//  Created by Artemiy Zuzin on 19.05.2022.
//

import Foundation
import Combine
import SwiftUI

final class DataManager: ObservableObject {
    
    init() {
        self.getAllPlaces()
    }
    
    private let urlConstructor = URLConstructor.default
    var userID: UUID? {
        didSet {
            self.getAllUserPlaces()
        }
    }
    
    @Published var allPlaces = [Place]()
    @Published var allUserPlaces = [Place]()
        
    func getAllPlaces() {
        URLSession.shared.dataTaskPublisher(for: self.urlConstructor.allPlacesURL())
            .tryMap { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
                
                return element.data
            }
            .decode(type: [Place].self, decoder: JSONDecoder())
            .replaceError(with: [Place]())
            .receive(on: RunLoop.main)
            .assign(to: &self.$allPlaces)
    }
    
    func getAllUserPlaces() {
        URLSession.shared.dataTaskPublisher(for: self.urlConstructor.allUserPlacesURL(userID: self.userID))
            .tryMap { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else { throw URLError(.badServerResponse) }
                
                return element.data
            }
            .decode(type: [Place].self, decoder: JSONDecoder())
            .replaceError(with: [Place]())
            .receive(on: RunLoop.main)
            .assign(to: &self.$allUserPlaces)
    }

    func postUser(user: User, didComplete: @escaping () -> Void, didNotComplete: @escaping (LogInErrors) -> Void) {
        var request = URLRequest(url: URLConstructor.default.newUserURL())
                        
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(user)
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                
                didNotComplete(.someError)
            } else {
                print("✅ place with id: \(String(describing: user.id)) posted.")
                
                didComplete()
            }
        }
        .resume()
    }
    
    func authUser(user: User, didComplete: @escaping () -> Void, didNotComplete: @escaping (SignInErrors) -> Void) {
        var request = URLRequest(url: URLConstructor.default.authUser())
        
        guard let base64EncodedCredential = "\(user.email):\(String(describing: user.password))".data(using: String.Encoding.utf8)?.base64EncodedString() else { return }
        
        let authString = "Basic \(base64EncodedCredential)"
        let urlSessionConfiguration = URLSessionConfiguration.default
        
        urlSessionConfiguration.httpAdditionalHeaders = ["Authorization" : authString]
        
        request.setValue(authString, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                
                didNotComplete(.someError)
            }
            
            guard let data = data else {
                print("❌ Error: data is equal to nil.")
                
                didNotComplete(.someError)
                
                return
            }
                        
            guard let user = try? JSONDecoder().decode(HashUser.self, from: data) else {
                print("❌Error: Decoding failed.")
                
                didNotComplete(.someError)
                
                return
            }
            
            print("✅ user with id: \(String(describing: user.id)) authenticated.")
            
            didComplete()
            
            self.userID = user.id
        }
        .resume()
    }
    
    func postPlace(place: Place) {
        var newPlace = place
        
        newPlace.userID = self.userID ?? UUID()
        
        var request = URLRequest(url: URLConstructor.default.newPlaceURL())
                
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(newPlace)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error, let code = (response as? HTTPURLResponse)?.statusCode, code != 200 {
                print("❌ Error: \(error.localizedDescription), status code equal: \(code)")
            } else {
                print("✅ place with id: \(String(describing: place.name) ) posted.")
                
                self.allPlaces.append(place)
                self.allUserPlaces.append(place)
            }
        }
        .resume()
    }
    
    func putPlace(place: Place) {
        var request = URLRequest(url: URLConstructor.default.putPlaceURL())
        
        request.httpMethod = HTTPMethod.put.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(place)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error, let code = (response as? HTTPURLResponse)?.statusCode, code != 200 {
                print("❌ Error: \(error.localizedDescription), status code equal: \(code)")
            } else {
                print("✅ place with id: \(String(describing: place.name) ) changed.")
                
                for i in 0 ..< self.allPlaces.count {
                    if place.id == self.allPlaces[i].id {
                        DispatchQueue.main.async {
                            self.allPlaces[i] = place
                        }
                    }
                }
                
                for i in 0 ..< self.allUserPlaces.count {
                    if place.id == self.allUserPlaces[i].id {
                        DispatchQueue.main.async {
                            self.allUserPlaces[i] = place
                        }
                    }
                }
            }
        }
        .resume()
        
    }
    
    func deletePlace(placeID: UUID) {
        var request = URLRequest(url: URLConstructor.default.placeURL(placeID: placeID))
        
        request.httpMethod = HTTPMethod.delete.rawValue
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
            } else {
                print("✅ place with id: \(placeID) deleted.")
                
                for i in 0 ..< self.allPlaces.count {
                    if self.allPlaces[i].id == placeID {
                        self.allPlaces.remove(at: i)
                    }
                }
                
                for i in 0 ..< self.allUserPlaces.count {
                    if self.allUserPlaces[i].id == placeID {
                        self.allUserPlaces.remove(at: i)
                    }
                }
            }
        }
        .resume()
    }
    
    private enum HTTPMethod: String {
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
}
