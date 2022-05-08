//
//  NavigationCoordinator.swift
//  CafeMap
//
//  Created by Artemiy Zuzin on 06.05.2022.
//

import Foundation

protocol Coordinatable {
    var coordinator: NavigationCoordinator? { get set }
}

final class NavigationCoordinator {
    
    func start() -> RegistrationView {
        return self.goToRegistration()
    }
    
    func goToCafeMap() -> PlacesMapView {
        let viewModel = PlacesMapViewModel()
        let view = PlacesMapView(viewModel: viewModel)
                
        viewModel.coordinator = self
        
        return view
    }
    
    func goToRegistration() -> RegistrationView {
        let viewModel = RegistrationViewModel()
        let view = RegistrationView(viewModel: viewModel)
        
        viewModel.coordinator = self
        
        return view
    }
    
}
