
import UIKit

protocol CellRecycler {
    func registerCell<Cell: ReusableView>(_ cellType: Cell.Type)
    func dequeueReusable<Cell: ReusableView>(for indexPath: IndexPath) -> Cell
}

extension CellRecycler where Self: UITableView {
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
    func registerCell<Cell>(_ cellType: Cell.Type) where Cell : ReusableView {
        register(cellType, forCellReuseIdentifier: Cell.reuseIdentifier)
    }
}

protocol ModelConfigurable {
    associatedtype M
    func configure(with model: M)
}

class ConfigurableCell<Model>: UITableViewCell, ModelConfigurable {
    typealias M = Model
    func configure(with model: Model) {
        fatalError("Not implemented")
    }
}

protocol CellProvider {
    associatedtype Model

    func configure<C: ModelConfigurable>(cell: C, with model: Model) where C.M == Model
}

extension CellProvider {
    func tableViewCell(for model: Model, in tableView: UITableView, at indexPath: IndexPath) -> ConfigurableCell<Model> {
        let c: ConfigurableCell<Model> = tableView.dequeueReusable(for: indexPath)
        configure(cell: c, with: model)
        return c
    }
}

//private class _AnyProviderBase<M>: CellProvider {
//    typealias Model = M
//
//    init() {
//        guard type(of: self) != _AnyProviderBase.self else {
//            fatalError()
//        }
//    }
//
//    func configure(cell: CellType, with model: M) {
//        fatalError("Not Implemented")
//    }
//}
//
//private class _AnyProviderBox<Concrete: CellProvider>: _AnyProviderBase<Concrete.Model, Concrete.CellType> {
//    var concrete: Concrete
//
//    init(_ concrete: Concrete) {
//        self.concrete = concrete
//    }
//
//    override func configure(cell: Concrete.CellType, with model: Concrete.Model) {
//        concrete.configure(cell: cell, with: model)
//    }
//}
//
//struct AnyTableViewCellProvider<M>: CellProvider {
//    typealias Model = M
//    typealias CellType = UITableViewCell
//
//    private let box: _AnyProviderBase<M, CellType>
//
//    init<P: CellProvider>(_ provider: P) where P.Model == M, P.CellType: UITableViewCell {
//        box = _AnyProviderBox(provider)
//    }
//
//    func configure(cell: UITableViewCell, with model: M) {
//        box.configure(cell: cell , with: model)
//    }
//}
