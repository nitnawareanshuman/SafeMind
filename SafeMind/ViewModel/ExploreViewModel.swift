//
//  ExploreViewModel.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//


import FirebaseFirestore
import Combine

class ExploreViewModel: ObservableObject {
    
    @Published var items: [ExploreItem] = []
    
    private let db = Firestore.firestore()
    
    func fetchContent(category: String) {
        db.collection("explore_content")
            .document(category)
            .collection("items")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Firestore error:", error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                DispatchQueue.main.async {
                    self.items = documents.compactMap { doc in
                        try? doc.data(as: ExploreItem.self)
                    }
                }
            }
    }
}
