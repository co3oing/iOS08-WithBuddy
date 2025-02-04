//
//  RegisterViewModel.swift
//  WithBuddy
//
//  Created by Inwoo Park on 2021/11/03.
//

import Foundation
import Combine

enum RegisterError: LocalizedError {
    case noBuddy
    case noType
    
    var errorDescription: String? {
        switch self {
        case .noBuddy: return "최소 한명 이상의 버디를 추가해 주세요."
        case .noType: return "최소 한개 이상의 모임 목적을 추가해 주세요."
        }
    }
}

class RegisterViewModel {
    
    private var date: Date?
    private var place: String?
    private var memo: String?
    private var checkedPurposeList: [CheckableInfo] {
        return self.purposeList.filter( { $0.check })
    }
    private(set) var addBuddySignal = PassthroughSubject<[Buddy], Never>()
    private(set) var registerDoneSignal = PassthroughSubject<Gathering, Never>()
    private(set) var registerFailSignal = PassthroughSubject<RegisterError, Never>()
    
    @Published private(set) var purposeList: [CheckableInfo] = []
    @Published private(set) var buddyList: [Buddy] = []
    @Published private(set) var pictures: [URL] = []
    
    private var buddyUseCase = BuddyUseCase(coreDataManager: CoreDataManager.shared)
    private var gatheringUseCase = GatheringUseCase(coreDataManager: CoreDataManager.shared)
    private var purposeUseCase = PurposeUseCase(coreDataManager: CoreDataManager.shared)
    
    init() {
        self.configure()
    }
    
    func didDatePicked(_ date: Date) {
        self.date = date
    }
    
    func didPlaceChanged(_ place: String) {
        self.place = place
    }
    
    func didPurposeTouched(_ idx: Int) {
        self.purposeList[idx].check.toggle()
    }
    
    func didBuddyAdded(_ buddy: Buddy) {
        self.buddyList.insert(buddy, at: 0)
    }
    
    func didBuddyUpdated(_ buddyList: [Buddy]) {
        self.buddyList = buddyList
    }
    
    func didMemoChanged(_ memo: String) {
        self.memo = memo
    }
    
    func didPicturePicked(_ picture: URL) {
        self.pictures.insert(picture, at: 0)
    }
    
    func didPictureDeleteTouched(in idx: Int) {
        if idx < self.pictures.count {
            self.pictures.remove(at: idx)
        }
    }
    
    func didBuddyDeleteTouched(in idx: Int) {
        if idx < self.buddyList.count {
            self.buddyList.remove(at: idx)
        }
    }
    
    func didDoneTouched() {
        if self.buddyList.isEmpty {
            self.registerFailSignal.send(RegisterError.noBuddy)
        } else if self.checkedPurposeList.isEmpty {
            self.registerFailSignal.send(RegisterError.noType)
        } else {
            guard let date = date else {
                return
            }
            let gathering = Gathering(
                id: UUID(),
                date: date,
                place: self.place,
                purpose: self.checkedPurposeList.map{ $0.engDescription },
                buddyList: self.buddyList,
                memo: self.memo,
                picture: self.pictures
            )
            self.gatheringUseCase.insertGathering(gathering)
            self.registerDoneSignal.send(gathering)
        }
    }
    
    func didAddBuddyTouched() {
        self.addBuddySignal.send(self.buddyList)
    }
    
    private func configure() {
        self.purposeList = PurposeCategory.allCases.map({ CheckableInfo(engDescription: "\($0)", korDescription: self.purposeUseCase.engToKor(eng: "\($0)"), check: false) })
    }
    
}
