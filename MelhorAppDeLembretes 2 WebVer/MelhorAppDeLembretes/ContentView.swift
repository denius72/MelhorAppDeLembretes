//
//  ContentView.swift
//  MelhorAppDeLembretes
//
//  Created by Denis on 08/10/22.
//

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    @State private var presentAlert = false
    @State private var presentAlertEdit = false
    @State private var presentAlertAuth = false
    @State var isShown = false
    @State var willMoveToNextScreen = false
    @State private var name: String = ""
    @State private var descript: String = ""
    @State private var beforename : String = ""
    @State private var duedate: Date = Date()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        if(item.name != nil){
                            Text("\n\(item.name!)")
                            Text("\n\(item.desc!)")
                            Text("\n\n\nLembrar em \(item.duedate!, formatter: itemFormatter)")
                            Button("Mudar data de Lembrete")
                            {
                                isShown = !isShown
                                item.duedate = duedate
                            }
                            if(isShown)
                            {
                                DatePicker("Mudar data de lembrete", selection: $duedate)
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .frame(maxHeight: 400)
                            }
                            Text("\nData de criação \(item.timestamp!, formatter: itemFormatter)")
                            Button(action: acionarviewedit)
                            {
                                Label("Editar Lembrete", systemImage: "pencil")
                            }.alert("Editar Lembrete", isPresented: $presentAlertEdit, actions: {
                                TextField("Nome", text: $name)
                                TextField("Descrição", text: $descript)
                                
                                Button("OK", action: {
                                    if item.name != nil
                                    {beforename = item.name!}
                                    
                                    item.timestamp = Date()
                                    item.name = name
                                    item.desc = descript
                                    editreminder(idd: item.idd)
                                })
                                Button("Cancelar", role: .cancel, action: {})
                            }, message: {
                                Text("Por favor, coloque as informações desejadas.")
                            })
                            Button("\nDeletar da nuvem", action: {
                                let db = Firestore.firestore()
                                //TO DO = excluir obj do firebase com id se possivel
                                db.collection("users").document(Auth.auth().currentUser!.uid+"."+String(item.name!)).delete() { err in
                                    if let err = err {
                                        print("Error removing document: \(err)")
                                    } else {
                                        print("Document successfully removed!")
                                    }
                                }
                            })
                        }
                    } label: {
                        if(item.name != nil){
                            Text(item.name!)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: AboutView()) {
                        Text("Sobre")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    if Auth.auth().currentUser == nil{
                        Button(action: acionarviewauth)
                        {
                            Label("Login", systemImage: "key")
                            
                        }
                        .alert("Login", isPresented: $presentAlertAuth, actions: {
                            TextField("E-mail", text: $name)
                            TextField("Senha", text: $descript)
                            
                            Button("OK", action: {
                                FirebaseAuth.Auth.auth().signIn(withEmail: name, password: descript)
                                
                            })
                            Button("Cancelar", role: .cancel, action: {})
                        }, message: {
                            Text("Insira as credenciais para autenticar.")
                        })
                    }
                    else
                    {
                        Button(action: acionarviewauth)
                        {
                            Label("Logout", systemImage: "key")
                            
                        }
                        .alert("Logout", isPresented: $presentAlertAuth, actions: {
                            
                            Button("OK", action: {
                                let firebaseAuth = Auth.auth()
                                do {
                                  try firebaseAuth.signOut()
                                } catch let signOutError as NSError {
                                  print("Error signing out: %@", signOutError)
                                }
                            })
                            Button("Cancelar", role: .cancel, action: {})
                        }, message: {
                            Text("Aperte OK para deslogar.")
                        })
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: refresh)
                    {
                        Label("Refrescar", systemImage: "arrow.2.circlepath")
                        
                    }
                }
                ToolbarItem {
                    Button(action: acionarview)
                    {
                        Label("Adicionar Lembrete", systemImage: "plus")
                        
                    }
                    .alert("Adicionar Lembrete", isPresented: $presentAlert, actions: {
                        TextField("Nome", text: $name)
                        TextField("Descrição", text: $descript)
                        
                        Button("OK", action: addItem)
                        Button("Cancelar", role: .cancel, action: {})
                    }, message: {
                        Text("Por favor, coloque as informações desejadas.")
                    })
                }
            }
            Text("Selecione o item")
        }
    }
    
    private func acionarview()
    {
        presentAlert = true
    }
    private func acionarviewedit()
    {
        presentAlertEdit = true
    }
    private func acionarviewauth()
    {
        presentAlertAuth = true
    }
    private func editreminder(idd:Int64)
    {
        let db = Firestore.firestore()
            db.collection("users").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    debugPrint("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        var str = "\(document.data())"
                        //let mp = Dictionary(document.data())
                        //debugPrint(document.documentID)
                        let data = document.data()
                        let tempid = data["id"] as? Int ?? -1
                        if tempid == idd
                        {
                            //TO DO = logica de update
                            
                            if Auth.auth().currentUser != nil{
                                print("logged in successfully")
                                
                                let docname = Auth.auth().currentUser!.uid+"."+String(beforename)
                                db.collection("users").document(docname).setData([
                                    "title": name,
                                    "desc": descript,
                                    "timestamp": Date(),
                                    "duedate": duedate,
                                    "id": idd

                                ], merge: true)
                            }
                            else
                            {
                                print("not logged in")
                            }
                        }
                    }
                }
            }
    }
    private func refresh(){
        let db = Firestore.firestore()
        for i in 0...items.endIndex-1
        {
            db.collection("users").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    debugPrint("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        var str = "\(document.data())"
                        //let mp = Dictionary(document.data())
                        //debugPrint(document.documentID)
                        let data = document.data()
                        let tempid = data["id"] as? Int ?? -1
                        if tempid == i
                        {
                            items[i].name = data["title"] as? String ?? ""
                            items[i].desc = data["desc"] as? String ?? ""
                            items[i].timestamp = Date()
                            items[i].duedate = duedate
                            
                        }
                    }
                }
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.duedate = duedate
            newItem.name = name
            newItem.desc = descript
            newItem.idd = Int64(items.endIndex)
            let db = Firestore.firestore()
            
            if Auth.auth().currentUser != nil{
                print("logged in successfully")
                
                let docname = Auth.auth().currentUser!.uid+"."+String(name)
                db.collection("users").document(docname).setData([
                    "title": name,
                    "desc": descript,
                    "timestamp": Date(),
                    "duedate": duedate,
                    "id": items.endIndex

                ], merge: true)
            }
            else
            {
                print("not logged in")
            }

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
