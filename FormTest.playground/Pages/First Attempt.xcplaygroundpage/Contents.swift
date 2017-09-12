//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport

/*
 # Protocols and Conformances
 */

protocol CellRecycler {
    associatedtype RootCell: ReusableView

    func registerCell<Cell: ReusableView>(_ cellType: Cell.Type)

    func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> RootCell
    func dequeueReusable<Cell: ReusableView>(for indexPath: IndexPath) -> Cell
}

extension CellRecycler {
    func dequeueReusable<Cell: ReusableView>(for indexPath: IndexPath) -> Cell {
        let c = dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath)
        return c as! Cell
    }
}

protocol ReusableView: class {
    static var reuseIdentifier: String { get }
}

extension ReusableView where Self: UIView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: ReusableView {}

extension UITableView: CellRecycler {
    typealias RootCell = UITableViewCell
    func registerCell<Cell>(_ cellType: Cell.Type) where Cell : ReusableView {
        register(cellType, forCellReuseIdentifier: Cell.reuseIdentifier)
    }
}

protocol CellProvider {
    associatedtype Model
    associatedtype CellType

    func configure(cell: CellType, with model: Model)
}

extension CellProvider {
    func cell<R: CellRecycler>(for model: Model, in recycler: R, at indexPath: IndexPath) -> CellType {
        let c: R.RootCell = recycler.dequeueReusable(for: indexPath)
        let cell = c as! CellType
        configure(cell: cell, with: model)
        return cell
    }
}

private class _AnyProviderBase<M, C>: CellProvider {
    typealias Model = M
    typealias CellType = C

    init() {
        guard type(of: self) != _AnyProviderBase.self else {
            fatalError()
        }
    }

    func configure(cell: CellType, with model: M) {
        fatalError("Not Implemented")
    }
}

private class _AnyTableProviderBase<M>: CellProvider {
    typealias Model = M
    typealias CellType = UITableViewCell

    init() {
        guard type(of: self) != _AnyTableProviderBase.self else {
            fatalError()
        }
    }

    func configure(cell: CellType, with model: M) {
        fatalError("Not Implemented")
    }
}

private class _AnyProviderBox<Concrete: CellProvider>: _AnyProviderBase<Concrete.Model, Concrete.CellType> {
    var concrete: Concrete

    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    override func configure(cell: Concrete.CellType, with model: Concrete.Model) {
        concrete.configure(cell: cell, with: model)
    }
}

private class _AnyTableProviderBox<Concrete: CellProvider>: _AnyTableProviderBase<Concrete.Model> {
    var concrete: Concrete

    init(_ concrete: Concrete) {
        self.concrete = concrete
    }

    override func configure(cell: UITableViewCell, with model: Concrete.Model) {
        let castCell = cell as! Concrete.CellType
        concrete.configure(cell: castCell, with: model)
    }
}

struct AnyTableViewCellProvider<M>: CellProvider {
    typealias Model = M
    typealias CellType = UITableViewCell

    private let box: _AnyTableProviderBase<M>

    init<P: CellProvider>(_ provider: P) where P.Model == M, P.CellType: UITableViewCell {
        box = _AnyTableProviderBox(provider)
    }

    func configure(cell: UITableViewCell, with model: M) {
        box.configure(cell: cell , with: model)
    }
}

protocol TableViewCellType {
    var tableViewCell: UITableViewCell { get }
}

extension UITableViewCell: TableViewCellType {
    var tableViewCell: UITableViewCell {
        return self
    }
}

/*
 # The Data Types
 */

struct DataA {
    let title: String
}

//struct ProviderA: CellProvider {
//    typealias Model = DataA
//    typealias CellType = CellA
//
//    func configure(cell: CellA, with model: DataA) {
//        cell.textLabel?.text = model.title
//    }
//}

struct DataB {
    let title: String
}

//struct ProviderB: CellProvider {
//    typealias Model = DataB
//    typealias CellType = CellB
//
//    func configure(cell: CellB, with model: DataB) {
//        cell.textLabel?.text = model.title
//    }
//}

class CellA: UITableViewCell {}

class CellB: UITableViewCell {}

/*
 # A Sample Data Source
 */

class DataSource: NSObject, UITableViewDataSource {
    var typeA = [DataA]()
    var typeB = [DataB]()

    private func text(at indexPath: IndexPath) -> String {
        switch indexPath.section {
        case 0:
            return typeA[indexPath.row].title
        case 1:
            return typeB[indexPath.row].title
        default:
            fatalError()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? typeA.count : typeB.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = indexPath.section == 0 ? CellA.self : CellB.self
        let cell = tableView.dequeueReusableCell(withIdentifier: type.reuseIdentifier, for: indexPath)
        var str = indexPath.section == 0 ? "Type A" : "Type B"
        str = "\(str) - \(text(at: indexPath))"
        cell.textLabel?.text = str
        return cell
    }
}

/*
 # A Generic Data Source
 */

struct TableModel {
    let dataA: DataA
    let dataB: DataB
}

class GenericDS<TM>: NSObject, UITableViewDataSource {
    var providers: [AnyTableViewCellProvider<TM>]
    var model: TM

    init(_ m: TM) {
        model = m
        providers = []
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return providers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let provider = providers[indexPath.row]
        return provider.cell(for: model, in: tableView, at: indexPath).tableViewCell
    }
}

/*
 # The Test
 */

let a = DataA(title: "Hello")
let b = DataB(title: "World")

let ds = DataSource()
ds.typeA = [DataA(title: "Hello")]
ds.typeB = [DataB(title: "World")]

let tm = TableModel(dataA: a, dataB: b)
let gds = GenericDS<TableModel>(tm)

struct ProviderA: CellProvider {
    typealias Model = TableModel
    typealias CellType = CellA

    func configure(cell: CellA, with model: TableModel) {
        cell.textLabel?.text = model.dataA.title
    }
}

struct ProviderB: CellProvider {
    typealias Model = TableModel
    typealias CellType = CellB

    func configure(cell: CellB, with model: TableModel) {
        cell.textLabel?.text = model.dataB.title
    }
}

let anyA = AnyTableViewCellProvider(ProviderA())
let anyB = AnyTableViewCellProvider(ProviderB())
gds.providers = [anyA, anyB]

let tv = UITableView(frame: UIScreen.main.bounds)
tv.registerCell(CellA.self)
tv.registerCell(CellB.self)
tv.dataSource = gds

let container = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 720))
container.addSubview(tv)
PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.liveView = container

