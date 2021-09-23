//
//  BrowserTabEmptyView.swift
//  OrionUI
//
//  Created by Amer Hukić on 23. 9. 2021..
//

import UIKit

class BrowserTabEmptyView: UIView {
  let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private extension BrowserTabEmptyView {
  func setupView() {
    backgroundColor = .white
    setupImageView()
  }
  
  func setupImageView() {
    imageView.image = UIImage(named: "SafariEmptyTabBackground")
    imageView.contentMode = .scaleAspectFit
    addSubview(imageView)
    imageView.snp.makeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      $0.bottom.equalToSuperview().inset(130)
    }
  }
}
