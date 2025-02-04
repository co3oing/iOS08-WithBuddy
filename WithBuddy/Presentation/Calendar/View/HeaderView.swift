//
//  HeaderView.swift
//  WithBuddy
//
//  Created by 이나정 on 2021/11/02.
//

import UIKit

class HeaderView: UIView {
    
    private let userFaceImageView = UIImageView()
    private let userCommentLabel = PurpleLabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureHeaderContent()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configureHeaderContent()
    }
    
    func update(face: String) {
        self.userFaceImageView.image = UIImage(named: face)
    }
    
    func reloadHeaderComment(text: String) {
        self.userCommentLabel.text = text
    }
    
    private func configureHeaderContent() {
        self.configureUserFaceImageView()
        self.configureUserCommentLabel()
    }
    
    private func configureUserFaceImageView() {
        self.addSubview(userFaceImageView)
        self.userFaceImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.userFaceImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.userFaceImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.userFaceImageView.widthAnchor.constraint(equalToConstant: 70),
            self.userFaceImageView.heightAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func configureUserCommentLabel() {
        self.addSubview(userCommentLabel)
        self.userCommentLabel.numberOfLines = 0
        self.userCommentLabel.font = .systemFont(ofSize: 14)
        self.userCommentLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.userCommentLabel.leadingAnchor.constraint(equalTo: self.userFaceImageView.trailingAnchor, constant: 5),
            self.userCommentLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.userCommentLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            self.userCommentLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
}
