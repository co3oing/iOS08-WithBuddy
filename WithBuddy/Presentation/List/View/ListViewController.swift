//
//  ListViewController.swift
//  WithBuddy
//
//  Created by 박정아 on 2021/11/01.
//

import UIKit
import Combine

final class ListViewController: UIViewController {
    
    private let searchView = SearchView()
    private let listTableView = UITableView()
    
    private lazy var listDataSource = UITableViewDiffableDataSource<Int, Gathering>(tableView: self.listTableView) { (tableView: UITableView, indexPath: IndexPath, itemIdentifier: Gathering) -> UITableViewCell? in
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ListTableViewCell.identifier, for: indexPath) as? ListTableViewCell else { return UITableViewCell() }
        cell.update(date: itemIdentifier.date, buddyImageList: itemIdentifier.buddyList.map{ $0.face }, typeList: itemIdentifier.purpose)
        return cell
    }
    
    private let listViewModel = ListViewModel(
        buddyUseCase: BuddyUseCase(
            coreDataManager: CoreDataManager.shared
        ),
        gatheringUseCase: GatheringUseCase(
            coreDataManager: CoreDataManager.shared
        )
    )
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configure()
        self.bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.listViewModel.fetch()
        self.searchView.reset()
    }
    
    private func configure() {
        self.configureSearchView()
        self.configureTableView()
    }
    
    private func bind() {
        self.listViewModel.$gatheringList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] getheringList in
                self?.reloadGathering(list: getheringList)
            }
            .store(in: &self.cancellables)
    }
    
    private func configureSearchView() {
        self.view.addSubview(self.searchView)
        self.searchView.searchTextField.delegate = self
        self.searchView.layer.cornerRadius = 10
        self.searchView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.searchView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.searchView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.searchView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            self.searchView.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configureTableView() {
        self.view.addSubview(self.listTableView)
        self.listTableView.delegate = self
        self.listTableView.backgroundColor = .clear
        self.listTableView.register(ListTableViewCell.self, forCellReuseIdentifier: ListTableViewCell.identifier)
        
        let panGesture = UIPanGestureRecognizer()
        panGesture.delegate = self
        self.listTableView.addGestureRecognizer(panGesture)
        self.listTableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:))))
        
        self.listTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.listTableView.topAnchor.constraint(equalTo: self.searchView.bottomAnchor, constant: 20),
            self.listTableView.leadingAnchor.constraint(equalTo: self.searchView.leadingAnchor),
            self.listTableView.trailingAnchor.constraint(equalTo: self.searchView.trailingAnchor),
            self.listTableView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func reloadGathering(list: [Gathering]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Gathering>()
        snapshot.appendSections([0])
        snapshot.appendItems(list)
        self.listDataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func reloadGathering(filter: String) {
        let gatheringList = self.listViewModel.gatheringList
        let filtered = gatheringList.filter{ $0.buddyList.contains{ $0.name.contains(filter) } }
        var snapshot = NSDiffableDataSourceSnapshot<Int, Gathering>()
        snapshot.appendSections([0])
        if filter.isEmpty {
            snapshot.appendItems(gatheringList)
        } else {
            snapshot.appendItems(filtered)
            self.listViewModel.searched(list: filtered)
        }
        self.listDataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func deleteGathering(index: Int) {
        self.listViewModel.deleteGathering(index: index)
    }
    
    private func editGathering(gathering: Gathering) {
        let viewController = GatheringEditViewController()
        viewController.configure(by: gathering)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            self.view.endEditing(true)
        }
        sender.cancelsTouchesInView = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

extension ListViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else { return }
        self.reloadGathering(filter: text)
    }
    
}

extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let viewController = GatheringDetailViewController()
        viewController.configure(by: self.listViewModel[indexPath.item])
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "삭제") { _, _, completion in
            self.deleteGathering(index: indexPath.row)
            completion(true)
        }
        deleteAction.backgroundColor = UIColor(named: "GraphRed")
        deleteAction.image = UIImage(named: "FaceRed1")

        let editAction = UIContextualAction(style: .normal, title: "편집") { _, _, completion in
            self.editGathering(gathering: self.listViewModel[indexPath.row])
            completion(true)
        }
        editAction.backgroundColor = UIColor(named: "GraphPurple2")
        editAction.image = UIImage(named: "FacePurple1")

        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat.tableViewHeight
    }
    
}

extension ListViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool{
        self.view.endEditing(true)
        return true
   }
}
