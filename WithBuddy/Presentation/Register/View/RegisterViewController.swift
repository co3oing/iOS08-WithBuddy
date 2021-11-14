//
//  RegisterViewController.swift
//  WithBuddy
//
//  Created by 김두연 on 2021/11/01.
//

import UIKit
import Combine

class RegisterViewController: UIViewController {
    
    private lazy var scrollView = UIScrollView()
    private lazy var contentView = UIView()
    
    private lazy var dateTitleLabel = TitleLabel()
    private lazy var dateBackgroundView = UIView()
    private lazy var dateContentLabel = UILabel()
    private lazy var datePickButton = UIButton()
  
    private lazy var placeTitleLabel = TitleLabel()
    private lazy var placeBackgroundView = UIView()
    private lazy var placeTextField = UITextField()
    
    private lazy var typeView = PurposeSelectView()
    
    private lazy var buddyTitleLabel = TitleLabel()
    private lazy var buddyAddButton = UIButton()
    private lazy var buddyCollectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    private lazy var buddyDataSource = UICollectionViewDiffableDataSource<Int, Buddy>(collectionView: self.buddyCollectionView) { (collectionView: UICollectionView, indexPath: IndexPath, itemIdentifier: Buddy) -> UICollectionViewCell? in
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageTextCollectionViewCell.identifier, for: indexPath) as? ImageTextCollectionViewCell else { preconditionFailure() }
        cell.update(image: UIImage(named: itemIdentifier.face), text: itemIdentifier.name)
        return cell
    }
    
    private lazy var memoTitleLabel = TitleLabel()
    private lazy var memoBackgroundView = UIView()
    private lazy var memoTextView = UITextView()
    
    private lazy var pictureTitleLabel = TitleLabel()
    private lazy var pictureView = PictureView()
    
    private lazy var datePicker = UIDatePicker()
    private lazy var dateToolBar = UIToolbar()
    
    private var registerViewModel = RegisterViewModel()
    private var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind()
        self.configure()
        self.registerViewModel.didStartDatePicked(Date())
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "완료", style: .done, target: self, action: #selector(self.addGathering))
    }
    
    private func bind() {
        self.dataBind()
        self.signalBind()
    }
    
    private func dataBind() {
        self.registerViewModel.$startDateString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                self?.dateContentLabel.text = date
            }
            .store(in: &self.cancellables)
        
        self.registerViewModel.$purposeList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] purposeList in
                self?.typeView.changeSelectedType(purposeList)
            }
            .store(in: &self.cancellables)
        
        self.registerViewModel.$buddyList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] buddyList in
                var snapshot = NSDiffableDataSourceSnapshot<Int, Buddy>()
                if buddyList.isEmpty {
                    snapshot.appendSections([0])
                    snapshot.appendItems([Buddy(id: UUID(), name: "친구없음", face: "FacePurple1")])
                } else {
                    snapshot.appendSections([0])
                    snapshot.appendItems(buddyList)
                }
                self?.buddyDataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &self.cancellables)
        
        self.registerViewModel.$pictures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pictures in
                self?.pictureView.pictureListReload(pictures)
            }
            .store(in: &self.cancellables)
    }
    
    private func signalBind() {
        self.registerViewModel.registerDoneSignal
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] in
                self?.alertSuccess()
            }
            .store(in: &self.cancellables)
        
        self.registerViewModel.registerFailSignal
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] result in
                self?.alertError(result)
            }
            .store(in: &self.cancellables)
        
        self.registerViewModel.addBuddySignal
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] buddyList in
                let buddyChoiceViewController = BuddyChoiceViewController()
                buddyChoiceViewController.delegate = self
                buddyChoiceViewController.configureBuddyList(by: buddyList)
                self?.navigationController?.pushViewController(buddyChoiceViewController, animated: true)
            }
            .store(in: &self.cancellables)
    }
    
    private func configure() {
        self.view.backgroundColor = UIColor(named: "BackgroundPurple")
        
        self.configureScrollView()
        self.configureContentView()
        self.configureDatePart()
        self.configurePlacePart()
        self.configureTypeView()
        self.configureBuddyPart()
        self.configureMemoPart()
        self.configurePictureView()
    }
    
    private func configureScrollView() {
        self.view.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            self.scrollView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor),
            self.scrollView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor)
        ])
    }
    
    private func configureContentView() {
        self.scrollView.addSubview(self.contentView)
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapEmptySpace)))
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
            self.contentView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
            self.contentView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
            self.contentView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor)
        ])
    }
    
    // MARK: - DatePart
    
    private func configureDatePart() {
        self.configureDateTitle()
        self.configureDateBackground()
        self.configureDateContent()
        self.configureDatePickButton()
    }
    
    private func configureDateTitle() {
        self.contentView.addSubview(self.dateTitleLabel)
        self.dateTitleLabel.text = "모임 날짜"
        self.dateTitleLabel.textColor = UIColor(named: "LabelPurple")
        
        self.dateTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.dateTitleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: .innerTopInset),
            self.dateTitleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: .outsideLeadingInset),
            self.dateTitleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: .outsideTrailingInset),
            self.dateTitleLabel.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configureDateBackground() {
        self.contentView.addSubview(self.dateBackgroundView)
        self.dateBackgroundView.backgroundColor = .white
        self.dateBackgroundView.layer.cornerRadius = 10
        
        self.dateBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.dateBackgroundView.topAnchor.constraint(equalTo: self.dateTitleLabel.bottomAnchor, constant: .innerTopInset),
            self.dateBackgroundView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: .outsideLeadingInset),
            self.dateBackgroundView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: .outsideTrailingInset),
            self.dateBackgroundView.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configureDateContent() {
        self.dateBackgroundView.addSubview(self.dateContentLabel)
        
        self.dateContentLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.dateContentLabel.leftAnchor.constraint(equalTo: self.dateBackgroundView.leftAnchor, constant: .innerLeadingInset),
            self.dateContentLabel.centerYAnchor.constraint(equalTo: self.dateBackgroundView.centerYAnchor)
        ])
    }
    
    private func configureDatePickButton() {
        self.dateBackgroundView.addSubview(self.datePickButton)
        self.datePickButton.setImage(UIImage(systemName: "calendar"), for: .normal)
        self.datePickButton.sizeToFit()
        self.datePickButton.addTarget(self, action: #selector(self.onDateButtonTouched(_:)), for: .touchUpInside)
        
        self.datePickButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.datePickButton.rightAnchor.constraint(equalTo: self.dateBackgroundView.rightAnchor, constant: .innerTrailingInset),
            self.datePickButton.centerYAnchor.constraint(equalTo: self.dateBackgroundView.centerYAnchor)
        ])
    }
    
    @objc private func onDateButtonTouched(_ sender: UIButton) {
        self.view.addSubview(self.datePicker)
        self.datePicker.translatesAutoresizingMaskIntoConstraints = false
        self.datePicker.autoresizingMask = .flexibleWidth
        self.datePicker.datePickerMode = .date
        self.datePicker.preferredDatePickerStyle = .inline
        self.datePicker.locale = Locale(identifier: "ko-KR")
        self.datePicker.timeZone = .autoupdatingCurrent
        self.datePicker.backgroundColor = .white
        
        NSLayoutConstraint.activate([
            self.datePicker.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.datePicker.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.datePicker.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.datePicker.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        self.view.addSubview(self.dateToolBar)
        self.dateToolBar.translatesAutoresizingMaskIntoConstraints = false
        self.dateToolBar.barStyle = .default
        self.dateToolBar.items = [UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.onDatePickDoneTouched))]
        self.dateToolBar.sizeToFit()
        
        NSLayoutConstraint.activate([
            self.dateToolBar.bottomAnchor.constraint(equalTo: self.datePicker.topAnchor),
            self.dateToolBar.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.dateToolBar.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.dateToolBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func onDatePickDoneTouched() {
        self.registerViewModel.didStartDatePicked(self.datePicker.date)
        self.datePicker.removeFromSuperview()
        self.dateToolBar.removeFromSuperview()
    }
    
    // MARK: - PlacePart
    
    private func configurePlacePart() {
        self.configurePlaceTitle()
        self.configurePlaceBackground()
        self.configurePlaceTextField()
    }
    
    private func configurePlaceTitle() {
        self.contentView.addSubview(self.placeTitleLabel)
        self.placeTitleLabel.text = "모임 장소"
        self.placeTitleLabel.textColor = UIColor(named: "LabelPurple")
        
        self.placeTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.placeTitleLabel.topAnchor.constraint(equalTo: self.dateBackgroundView.bottomAnchor, constant: .outsideTopInset),
            self.placeTitleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: .outsideLeadingInset),
            self.placeTitleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: .outsideTrailingInset),
            self.placeTitleLabel.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configurePlaceBackground() {
        self.contentView.addSubview(self.placeBackgroundView)
        self.placeBackgroundView.backgroundColor = .systemBackground
        self.placeBackgroundView.layer.cornerRadius = 10
        
        self.placeBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.placeBackgroundView.topAnchor.constraint(equalTo: self.placeTitleLabel.bottomAnchor, constant: .innerTopInset),
            self.placeBackgroundView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: .outsideLeadingInset),
            self.placeBackgroundView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: .outsideTrailingInset),
            self.placeBackgroundView.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configurePlaceTextField() {
        self.placeBackgroundView.addSubview(self.placeTextField)
        if let color = UIColor(named: "LabelPurple") {
            self.placeTextField.attributedPlaceholder = NSAttributedString(string: "모임 장소를 적어주세요", attributes: [NSAttributedString.Key.foregroundColor: color])
        }
        self.placeTextField.delegate = self
        
        self.placeTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.placeTextField.topAnchor.constraint(equalTo: self.placeBackgroundView.topAnchor),
            self.placeTextField.leftAnchor.constraint(equalTo: self.placeBackgroundView.leftAnchor, constant: .innerLeadingInset),
            self.placeTextField.rightAnchor.constraint(equalTo: self.placeBackgroundView.rightAnchor, constant: .innerTrailingInset),
            self.placeTextField.bottomAnchor.constraint(equalTo: self.placeBackgroundView.bottomAnchor)
        ])
    }
    
    // MARK: - PurposePart
    
    private func configureTypeView() {
        self.contentView.addSubview(self.typeView)
        self.typeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.typeView.topAnchor.constraint(equalTo: self.placeBackgroundView.bottomAnchor, constant: 40),
            self.typeView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
            self.typeView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20)
        ])
        self.typeView.delegate = self
    }
    
    // MARK: - BuddyPart
    
    private func configureBuddyPart() {
        self.configureBuddyTitle()
        self.configureBuddyAddButton()
        self.configureBuddyCollectionView()
    }
    
    private func configureBuddyTitle() {
        self.contentView.addSubview(self.buddyTitleLabel)
        self.buddyTitleLabel.text = "버디 추가"
        self.buddyTitleLabel.textColor = UIColor(named: "LabelPurple")
        
        self.buddyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.buddyTitleLabel.topAnchor.constraint(equalTo: self.typeView.bottomAnchor, constant: .outsideTopInset),
            self.buddyTitleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: .outsideLeadingInset),
            self.buddyTitleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: .outsideTrailingInset),
            self.buddyTitleLabel.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configureBuddyAddButton() {
        self.contentView.addSubview(self.buddyAddButton)
        let config = UIImage.SymbolConfiguration(
            pointSize: 60, weight: .medium, scale: .default)
        let image = UIImage(systemName: "plus.circle", withConfiguration: config)
        self.buddyAddButton.setImage(image, for: .normal)
        self.buddyAddButton.addTarget(self, action: #selector(self.onBuddyAddButtonTouched(_:)), for: .touchUpInside)
        
        self.buddyAddButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.buddyAddButton.topAnchor.constraint(equalTo: self.buddyTitleLabel.bottomAnchor, constant: .innerTopInset),
            self.buddyAddButton.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: .outsideLeadingInset),
            self.buddyAddButton.widthAnchor.constraint(equalToConstant: 60),
            self.buddyAddButton.heightAnchor.constraint(equalTo: self.buddyAddButton.widthAnchor)
        ])
    }
    
    private func configureBuddyCollectionView() {
        self.contentView.addSubview(self.buddyCollectionView)
        self.buddyCollectionView.backgroundColor = .clear
        self.buddyCollectionView.showsHorizontalScrollIndicator = false
        self.buddyCollectionView.delegate = self
        
        self.buddyCollectionView.register(ImageTextCollectionViewCell.self, forCellWithReuseIdentifier: ImageTextCollectionViewCell.identifier)
        
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 90)
        
        self.buddyCollectionView.collectionViewLayout = layout
        
        self.buddyCollectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.buddyCollectionView.topAnchor.constraint(equalTo: self.buddyAddButton.topAnchor),
            self.buddyCollectionView.leftAnchor.constraint(equalTo: self.buddyAddButton.rightAnchor, constant: 10),
            self.buddyCollectionView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: .outsideLeadingInset),
            self.buddyCollectionView.heightAnchor.constraint(equalToConstant: 90)
        ])
    }
    
    @objc private func onBuddyAddButtonTouched(_ sender: UIButton) {
        self.registerViewModel.addBuddyDidTouched()
    }
    
    // MARK: - MemoPart
    
    private func configureMemoPart() {
        self.configureMemoTitle()
        self.configureMemoBackground()
        self.configureMemoTextView()
    }
    
    private func configureMemoTitle() {
        self.contentView.addSubview(self.memoTitleLabel)
        self.memoTitleLabel.text = "모임 장소"
        self.memoTitleLabel.textColor = UIColor(named: "LabelPurple")
        
        self.memoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.memoTitleLabel.topAnchor.constraint(equalTo: self.buddyCollectionView.bottomAnchor, constant: .outsideTopInset),
            self.memoTitleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: .outsideLeadingInset),
            self.memoTitleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: .outsideTrailingInset),
            self.memoTitleLabel.heightAnchor.constraint(equalToConstant: 45)
        ])
    }
    
    private func configureMemoBackground() {
        self.contentView.addSubview(self.memoBackgroundView)
        self.memoBackgroundView.backgroundColor = .systemBackground
        self.memoBackgroundView.layer.cornerRadius = 10
        
        self.memoBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.memoBackgroundView.topAnchor.constraint(equalTo: self.memoTitleLabel.bottomAnchor, constant: .innerTopInset),
            self.memoBackgroundView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: .outsideLeadingInset),
            self.memoBackgroundView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: .outsideTrailingInset),
            self.memoBackgroundView.heightAnchor.constraint(equalToConstant: 140)
        ])
    }
    
    private func configureMemoTextView() {
        self.memoBackgroundView.addSubview(self.memoTextView)
        self.memoTextView.backgroundColor = .systemBackground
        self.memoTextView.font =  UIFont.systemFont(ofSize: 15, weight: .medium)
        self.memoTextView.textContentType = .none
        self.memoTextView.autocapitalizationType = .none
        self.memoTextView.autocorrectionType = .no
        self.memoTextView.delegate = self
        self.memoTextView.text = "모임에 대한 메모를 적어주세요."
        self.memoTextView.textColor = UIColor(named: "LabelPurple")
        
        self.memoTextView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.memoTextView.topAnchor.constraint(equalTo: self.memoBackgroundView.topAnchor, constant: 20),
            self.memoTextView.leftAnchor.constraint(equalTo: self.memoBackgroundView.leftAnchor, constant: 20),
            self.memoTextView.rightAnchor.constraint(equalTo: self.memoBackgroundView.rightAnchor, constant: -20),
            self.memoTextView.bottomAnchor.constraint(equalTo: self.memoBackgroundView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - PicturePart
    
    private func configurePictureView() {
        self.contentView.addSubview(self.pictureView)
        self.pictureView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.pictureView.topAnchor.constraint(equalTo: self.memoBackgroundView.bottomAnchor, constant: .outsideTopInset),
            self.pictureView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20),
            self.pictureView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20),
            self.pictureView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
        self.pictureView.delegate = self
    }
    
    // MARK: - CompletePart
    
    private func alertSuccess() {
        let alert = UIAlertController(title: "등록 완료", message: "모임 등록이 완료되었습니다!", preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func alertError(_ error: RegisterError) {
        let alert = UIAlertController(title: "등록 실패", message: error.errorDescription, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in })
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func addGathering() {
        self.registerViewModel.didDoneTouched()
    }
    
    @objc private func tapEmptySpace(){
        self.view.endEditing(true)
    }
}

extension RegisterViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { _ in
            let delete = UIAction(title: NSLocalizedString("삭제", comment: ""),
                                  image: UIImage(systemName: "trash")) { _ in
                self.registerViewModel.didBuddyDeleteTouched(in: indexPath.item)
            }
            return UIMenu(title: "이 버디를", children: [delete])
        })
    }
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            self.registerViewModel.didPlaceFinished(text)
        }
        textField.resignFirstResponder()
        return true
    }
}

extension RegisterViewController: UITextViewDelegate {
    func textViewShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            self.registerViewModel.didMemoFinished(text)
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor(named: "LabelPurple") {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "모임에 대한 메모를 적어주세요."
            textView.textColor = UIColor(named: "LabelPurple")
        }
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let url = info[UIImagePickerController.InfoKey.imageURL] as? URL else {
            return
        }
        self.registerViewModel.didPicturePicked(url)
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension RegisterViewController: PurposeViewDelegate {
    func purposeDidSelected(_ idx: Int) {
        self.registerViewModel.didTypeTouched(idx)
    }
}

extension RegisterViewController: PictureViewDelegate {
    func pictureDidDeleted(_ idx: Int) {
        self.registerViewModel.didPictureDeleteTouched(in: idx)
    }
    
    func pictureButtonDidTouched() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
}

extension RegisterViewController: BuddyChoiceDelegate {
    func buddySelectingDidCompleted(_ buddyList: [Buddy]) {
        self.registerViewModel.buddyDidUpdated(buddyList)
    }
}
