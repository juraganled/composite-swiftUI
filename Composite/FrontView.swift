//
//  FrontView.swift
//  Composite
//
//  Created by Ricky Suprayudi on 18/05/22.
//

import SwiftUI
import CoreData

class ItemsList: ObservableObject {
    @Published var showNewProjectModal: Bool = false
    
    let container: NSPersistentContainer
    @Published var savedEntities: [ProjectEntity] = []
    
    @Published var totalCost: Int = 0
    @Published var totalTime: Double = 0
    
    init() {
        container = NSPersistentContainer(name: "ProjectContainer")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("ERROR LOADING CORE DATA. \(error)")
            } else {
                print("Successfully load core data!")
            }
        }
        fetchProjects()
    }
    
    func fetchProjects() {
        let request = NSFetchRequest<ProjectEntity>(entityName: "ProjectEntity")
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch let error {
            print("Error fetching. \(error)")
        }
        print("fetchProjects() savedEntities count = \(savedEntities.count)")
        totalCost = 0
        totalTime = 0.0
        for items in savedEntities {
            totalCost += Int(items.cost!)!
            totalTime += Double(items.time!)!
        }
    }
    
    func addProject(name: String, description: String, cost: String, time: String) {
        let newProject = ProjectEntity(context: container.viewContext)
        let id = UUID()
        newProject.name = name
        newProject.desc = description
        newProject.cost = cost
        newProject.time = time
        newProject.id = id
        saveData()
    }
    
    func deleteProject(indexset: IndexSet) {
        guard let index = indexset.first else { return }
        let entity = savedEntities[index]
        container.viewContext.delete(entity)
        saveData()
    }

    func deleteProjectEntity(entity: ProjectEntity) {
        container.viewContext.delete(entity)
        saveData()
    }

    func editProject(entity: ProjectEntity, newName: String, newDescription: String, newCost: String, newTime: String) {
        entity.name = newName
        entity.desc = newDescription
        entity.cost = newCost
        entity.time = newTime
        saveData()
    }

    func favoriteProject(entity: ProjectEntity) {
        entity.favorite.toggle()
        saveData()
    }

    func saveData() {
        do {
            try container.viewContext.save()
            fetchProjects()
        } catch let error {
            print("Error saving. \(error)")
        }
    }

}

struct FrontView: View {
    @StateObject var coreItem = ItemsList()

//    @State var projectName: String = ""
    
    @State var editing = [String]()
    @State var total_cost: Int = 0
    @State var total_time: Double = 0.0
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
//                    HStack {
//                        Text("Project Name: ")
//                            .fontWeight(.semibold)
//                            .padding(.leading, 10)
//                        TextField("noname", text: $projectName)
//                    }
//                    .padding(.vertical, 10)
                    VStack {
                        HStack {
                            Text("Total Cost: ")
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            Text("Rp.\(formatNumber(number: coreItem.totalCost)),-")
                                .padding(.horizontal, 10)
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 10)
                    VStack {
                        HStack {
                            Text("Total Time: ")
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.leading, 10)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            
                            Text("\(formatDouble(number: coreItem.totalTime)) hours")
                                .padding(.horizontal, 10)
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .padding(10)
                VStack {
                    HStack {
                        Text("Item List:")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.leading, 10)
                            .onAppear() {
                                total_cost = 0
                                total_time = 0.0
                            }
                        Spacer()
                    }
                    List {
                        ForEach (coreItem.savedEntities) { entity in
                            NavigationLink(destination: ItemDetailsView(detailEntity: entity, detailName: entity.name!, detailDesc: entity.desc!, detailCost: entity.cost!, detailTime: entity.time!)) {
                                HStack {
                                    VStack {
                                        HStack {
                                            Text(entity.name ?? "NO NAME")
                                                .font(.headline)
                                                .fontWeight(.medium)
                                                .foregroundColor(entity.favorite ? .green : .primary)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        HStack {
                                            Text(entity.desc ?? "no description")
                                                .font(.subheadline)
                                                .fontWeight(.light)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                    }
                                    Spacer()
                                    Text(entity.cost ?? "no cost")
                                        .font(.headline)
                                        .fontWeight(.light)
                                        .foregroundColor(.primary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    print("delete \(entity.name ?? "")")
                                    coreItem.deleteProjectEntity(entity: entity)
                                } label: {
                                    Label("Delete", systemImage: "trash.circle.fill")
                                        .accessibilityLabel("Delete item")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    coreItem.favoriteProject(entity: entity)
                                    print("favorite \(entity.favorite)")
                                } label: {
                                    Label("Favorite", systemImage: "heart.circle")
                                }
                                .tint(.green)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .padding(.leading, 10)
            }
            .navigationTitle("PROJECT CALCULATOR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        coreItem.showNewProjectModal = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .sheet(isPresented: $coreItem.showNewProjectModal) {
                        AddItemViewModal()
                    }
                }
            }
        }
        .environmentObject(coreItem)
    }
        
    func formatNumber(number: Int) -> String {
        let formatterDecimal = NumberFormatter()
        formatterDecimal.numberStyle = .decimal
        formatterDecimal.maximumFractionDigits = 0
        return formatterDecimal.string(from: number as NSNumber)!
    }

    func formatDouble(number: Double) -> String {
        let formatterDouble = NumberFormatter()
        formatterDouble.numberStyle = .decimal
        formatterDouble.maximumFractionDigits = 3
        return formatterDouble.string(from: number as NSNumber)!
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FrontView()
    }
}

struct AddItemViewModal: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var coreProject: ItemsList
    
    @State private var newName: String = ""
    @State private var newDesc: String = ""
    @State private var newCost: String = ""
    @State private var newTime: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Information")) {
                    VStack {
                        HStack {
                            Text("Name: ")
                                .font(.headline)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            TextField("insert name", text: $newName)
                                .font(.subheadline)
                        }
                    }
                    VStack {
                        HStack {
                            Text("Description: ")
                                .font(.headline)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            TextField("write description", text: $newDesc)
                                .font(.subheadline)
                        }
                    }
                    VStack {
                        HStack {
                            Text("Cost: ")
                                .font(.headline)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            TextField("in Rupiah", text: $newCost)
                                .keyboardType(.decimalPad)
                                .font(.subheadline)
                        }
                    }
                    VStack {
                        HStack {
                            Text("Time: ")
                                .font(.headline)
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            TextField("in hour...", text: $newTime)
                                .keyboardType(.decimalPad)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .navigationBarTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.saveProject()
                    } label: {
                        Text("Add")
                    }
                }
            }
        }
    }
    
    func saveProject() {
        guard !newName.isEmpty || !newDesc.isEmpty else { return }
        coreProject.addProject(name: newName, description: newDesc, cost: newCost, time: newTime)
        newName = ""
        newDesc = ""
        newCost = ""
        newTime = ""
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct ItemDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var coreProject: ItemsList
    
    @State var detailEntity: ProjectEntity
    
    @State var detailName: String = ""
    @State var detailDesc: String = ""
    @State var detailCost: String = ""
    @State var detailTime: String = ""
        
    var body: some View {
        VStack {
            NavigationView {
                Form {
                    Section(header: Text("Item Name")) {
                        TextField("Name", text: $detailName)
                            .font(.subheadline)
                    }
                    .font(.headline)
                    Section(header: Text("Item Description")) {
                        TextField("Description", text: $detailDesc)
                            .font(.subheadline)
                    }
                    .font(.headline)
                    Section(header: Text("Item Cost")) {
                        TextField("in Rupiah", text: $detailCost)
                            .keyboardType(.decimalPad)
                            .font(.subheadline)
                    }
                    .font(.headline)
                    Section(header: Text("Time")) {
                        TextField("in hour", text: $detailTime)
                            .keyboardType(.decimalPad)
                            .font(.subheadline)
                    }
                    .font(.headline)
                }
            }
            .navigationBarTitle("Item Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        guard !detailDesc.isEmpty || !detailName.isEmpty else { return }
                        coreProject.editProject(entity: detailEntity, newName: detailName, newDescription: detailDesc, newCost: detailCost, newTime: detailTime)
                        self.presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Save")
                    }
                }
            }
        }
    }
}
