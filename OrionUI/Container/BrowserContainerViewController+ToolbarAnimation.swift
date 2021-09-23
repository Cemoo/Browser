//
//  BrowserContainerViewController+ToolbarAnimation.swift
//  OrionUI
//
//  Created by Amer Hukić on 23. 9. 2021..
//

import UIKit

private extension BrowserContainerViewController {
  
  // MARK: Toolbar collapsing animation
  func setupCollapsingToolbarAnimator() {
    collapsingToolbarAnimator?.stopAnimation(true)
    collapsingToolbarAnimator?.finishAnimation(at: .current)
    contentView.addressBarsScrollViewBottomConstraint?.update(offset: contentView.addressBarsScrollViewCollapsingHalfwayBottomOffset)
    contentView.toolbarBottomConstraint?.update(offset: contentView.toolbarCollapsingHalfwayBottomOffset)
    collapsingToolbarAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
      self?.setAddressBarContainersAlpha(0)
      self?.contentView.layoutIfNeeded()
    }
    collapsingToolbarAnimator?.addCompletion { [weak self] _ in
      guard let self = self else { return }
      self.contentView.addressBarsScrollViewBottomConstraint?.update(offset: self.contentView.addressBarsScrollViewCollapsingFullyBottomOffset)
      self.contentView.toolbarBottomConstraint?.update(offset: self.contentView.toolbarCollapsingFullyBottomOffset)
      self.contentView.tabsScrollViewBottomConstraint?.update(offset: self.contentView.tabsScrollViewCollapsingBottomOffset)
      UIViewPropertyAnimator(duration: 0.1, curve: .easeOut) { [weak self] in
        guard let self = self else { return }
        self.currentAddressBar.containerView.transform = CGAffineTransform(scaleX: 1.2, y: 0.8)
        self.currentAddressBar.domainLabel.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        self.contentView.layoutIfNeeded()
      }.startAnimation()
    }
    collapsingToolbarAnimator?.pauseAnimation()
  }
  
  func reverseCollapsingToolbarAnimation() {
    // isReversed property does not work correctly with autolayout constraints so we have to manually animate back collapsing state
    // http://www.openradar.me/34674968
    guard let collapsingToolbarAnimator = collapsingToolbarAnimator else { return }
    contentView.addressBarsScrollViewBottomConstraint?.update(offset: contentView.addressBarsScrollViewCollapsingHalfwayBottomOffset * collapsingToolbarAnimator.fractionComplete)
    contentView.toolbarBottomConstraint?.update(offset: contentView.toolbarCollapsingHalfwayBottomOffset * collapsingToolbarAnimator.fractionComplete)
    contentView.layoutIfNeeded()
    collapsingToolbarAnimator.stopAnimation(true)
    collapsingToolbarAnimator.finishAnimation(at: .current)
    contentView.addressBarsScrollViewBottomConstraint?.update(offset: contentView.addressBarsScrollViewExpandingFullyBottomOffset)
    contentView.toolbarBottomConstraint?.update(offset: 0)
    UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
      self?.setAddressBarContainersAlpha(1)
      self?.contentView.layoutIfNeeded()
    }.startAnimation()
  }
  
  // MARK: Toolbar expanding animation
  func setupExpandingToolbarAnimator() {
    expandingToolbarAnimator?.stopAnimation(true)
    expandingToolbarAnimator?.finishAnimation(at: .current)
    contentView.addressBarsScrollViewBottomConstraint?.update(offset: contentView.addressBarsScrollViewExpandingHalfwayBottomOffset)
    contentView.toolbarBottomConstraint?.update(offset: contentView.toolbarExpandingHalfwayBottomOffset)
    expandingToolbarAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
      self?.contentView.layoutIfNeeded()
    }
    expandingToolbarAnimator?.addCompletion { [weak self] _ in
      guard let self = self else { return }
      self.contentView.toolbarBottomConstraint?.update(offset: self.contentView.toolbarExpandingFullyBottomOffset)
      self.contentView.addressBarsScrollViewBottomConstraint?.update(offset: self.contentView.addressBarsScrollViewExpandingFullyBottomOffset)
      self.contentView.tabsScrollViewBottomConstraint?.update(offset: self.contentView.tabsScrollViewExpandingBottomOffset)
      UIViewPropertyAnimator(duration: 0.1, curve: .easeOut) { [weak self] in
        self?.currentAddressBar.containerView.transform = .identity
        self?.currentAddressBar.domainLabel.transform = .identity
        self?.setAddressBarContainersAlpha(1)
        self?.contentView.layoutIfNeeded()
      }.startAnimation()
    }
    expandingToolbarAnimator?.pauseAnimation()
  }
  
  func reverseExpandingToolbarAnimation() {
    guard let expandingToolbarAnimator = expandingToolbarAnimator else { return }
    contentView.addressBarsScrollViewBottomConstraint?.update(offset: contentView.addressBarsScrollViewExpandingHalfwayBottomOffset * expandingToolbarAnimator.fractionComplete)
    contentView.toolbarBottomConstraint?.update(offset: contentView.toolbarExpandingHalfwayBottomOffset * expandingToolbarAnimator.fractionComplete)
    contentView.layoutIfNeeded()
    expandingToolbarAnimator.stopAnimation(true)
    expandingToolbarAnimator.finishAnimation(at: .current)
    contentView.addressBarsScrollViewBottomConstraint?.update(offset: contentView.addressBarsScrollViewCollapsingFullyBottomOffset)
    contentView.toolbarBottomConstraint?.update(offset: contentView.toolbarCollapsingFullyBottomOffset)
    UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
      self?.setAddressBarContainersAlpha(0)
      self?.contentView.layoutIfNeeded()
    }.startAnimation()
  }
  
  func setAddressBarContainersAlpha(_ alpha: CGFloat) {
    currentAddressBar.setContainerAlpha(alpha)
    leftAddressBar?.setContainerAlpha(alpha)
    rightAddressBar?.setContainerAlpha(alpha)
  }
}

// MARK: BrowserTabViewControllerDelegate
extension BrowserContainerViewController: BrowserTabViewControllerDelegate {
  func webViewDidScroll(yOffsetChange: CGFloat) {
    let offsetChangeBeforeFullAnimation = CGFloat(30)
    let animationFractionComplete = abs(yOffsetChange) / offsetChangeBeforeFullAnimation
    let tresholdBeforeAnimationCompletion = CGFloat(0.7)
    let isScrollingDown = yOffsetChange < 0
    
    if isScrollingDown {
      // if we are scrolling down and the toolbar is collapsed then we skip the animation
      guard !isCollapsed else { return }
      
      // if an animator does not exist (e.g. we just started the animation)
      // or if the animation completed once but user keeps scrolling without ending the pan gesture
      // then we need to recreate a new animator
      if collapsingToolbarAnimator == nil || collapsingToolbarAnimator?.state == .inactive {
        setupCollapsingToolbarAnimator()
      }
      
      if animationFractionComplete < tresholdBeforeAnimationCompletion {
        collapsingToolbarAnimator?.fractionComplete = animationFractionComplete
      } else {
        isCollapsed = true
        collapsingToolbarAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
      }
    } else {
      guard isCollapsed else { return }
      if expandingToolbarAnimator == nil || expandingToolbarAnimator?.state == .inactive {
        setupExpandingToolbarAnimator()
      }
      
      if animationFractionComplete < tresholdBeforeAnimationCompletion {
        expandingToolbarAnimator?.fractionComplete = animationFractionComplete
      } else {
        isCollapsed = false
        expandingToolbarAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
      }
    }
  }
  
  func webViewDidEndDragging() {
    // if the collapsing animator is active, but the toolbar is not fully collapsed then we need to revert the animation
    if let collapsingToolbarAnimator = collapsingToolbarAnimator,
       collapsingToolbarAnimator.state == .active,
       !isCollapsed {
      reverseCollapsingToolbarAnimation()
    }
    
    // if the expanding animator is active, but the toolbar is not fully expanded then we need to revert the animation
    if let expandingToolbarAnimator = expandingToolbarAnimator,
       expandingToolbarAnimator.state == .active,
       isCollapsed {
      reverseExpandingToolbarAnimation()
    }
    
    collapsingToolbarAnimator = nil
    expandingToolbarAnimator = nil
  }
}
