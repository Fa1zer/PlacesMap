//
//  CafeMapViewModel.swift
//  CafeMap
//
//  Created by Artemiy Zuzin on 05.05.2022.
//

import Foundation

final class CafeMapViewModel: ObservableObject, Coordinatable {
    
    var coordinator: NavigationCoordinator?
    
    private let model = CafeMapModel()
    
}
