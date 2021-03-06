//
//  NetworkManager.swift
//  CoronaLog
//
//  Created by Bryan Cuevas on 5/15/20.
//  Copyright © 2020 bryanCuevas. All rights reserved.
//

import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    func getWorldwideData(dateString: String, completion: @escaping (Result<WorldwideDataModel, CLErrors>) -> Void) {
        
        let headers = [
            "x-rapidapi-host": "covid-193.p.rapidapi.com",
            "x-rapidapi-key": apiKeys.rapidAPIKey
        ]
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://covid-193.p.rapidapi.com/history?day=\(dateString)&country=all")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] (data, response, error) -> Void in
            
            guard let self = self else { return }
            
            if let _ = error {
                completion(.failure(.unableToComplete))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let worldwideData = self.parseWorldwideDataFromJSON(json: json) else {
                    completion(.failure(.invalidResponse))
                    return
                }
                completion(.success(worldwideData))
                
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
        })
        dataTask.resume()
    }
    
    func getCasesByCountryData(completion: @escaping (Result<[CasesByCountryDataModel], CLErrors>) -> Void) {
        let headers = [
            "x-rapidapi-host": "covid-193.p.rapidapi.com",
            "x-rapidapi-key": apiKeys.rapidAPIKey
        ]
        
        let request = NSMutableURLRequest(url: NSURL(string: "https://covid-193.p.rapidapi.com/statistics")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { [weak self] (data, response, error) -> Void in
            guard let self = self else { return }
            
            if let _ = error {
                completion(.failure(.unableToComplete))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                
                guard let casesByCountryData = self.parseCasesByCountryDataFromJSON(json: json) else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                completion(.success(casesByCountryData))
                
            } catch {
                print("JSON error: \(error.localizedDescription)")
            }
        })
        dataTask.resume()
    }
}

extension NetworkManager { //Handle Data cleaning
    
    func parseWorldwideDataFromJSON(json: Any) -> WorldwideDataModel? {
        
        guard let entireJSON = json as? [String: Any] else{ return nil }
        
        guard let response = entireJSON["response"] as? [[String: Any]] else { return nil }
        
        guard let cases = response[0]["cases"] as? [String: Any] else { return nil }
        
        guard let totalCases = cases["total"] as? Int, let recovered = cases["recovered"] as? Int,
            let activeCases = cases["active"] as? Int, let criticalCases = cases["critical"] as? Int else {
                return nil
        }
        
        guard let deaths = response[0]["deaths"] as? [String: Any] else { return nil }
        
        guard let newDeathsString = deaths["new"] as? String, let totalDeaths = deaths["total"] as? Int else { return nil }
        
        let startIndex =  newDeathsString.index(newDeathsString.startIndex, offsetBy: 1)
        let endIndex = newDeathsString.endIndex
        
        guard let newDeathsInt = Int(newDeathsString[startIndex..<endIndex]) else { return nil}
        
        let worldWideDataModel = WorldwideDataModel(totalCases: totalCases, active: activeCases, recovered: recovered, critical: criticalCases, newDeaths: newDeathsInt, totalDeaths: totalDeaths)
        
        return worldWideDataModel
    }
    
    func parseCasesByCountryDataFromJSON(json: Any) -> [CasesByCountryDataModel]? {
        
        guard let entireJSON = json as? [String: Any] else{ return nil }
        guard let response = entireJSON["response"] as? [[String: Any]] else { return nil }
        
        var casesByCountryArray = [CasesByCountryDataModel]()
        
        for value in response {
            guard let countryName = value["country"] as? String else { return nil }
            guard let cases = value["cases"] as? [String: Any] else { return nil }
            guard let casesForCountry = cases["total"] as? Int else { return nil }
            let countryData = CasesByCountryDataModel(countryName: countryName, casesForCountry: casesForCountry)
            casesByCountryArray.append(countryData)
            
        }
        return casesByCountryArray.sorted(by: {$0.casesForCountry > $1.casesForCountry})
    }
}
