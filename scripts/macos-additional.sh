#!/bin/bash
# macOS 미션컨트롤 딜레이 완전 제거

defaults write com.apple.dock expose-animation-duration -float 0.0001
defaults write com.apple.dock expose-cluster-type -int 0
defaults write com.apple.dock springboard-show-duration -float 0.0001
defaults write com.apple.dock springboard-hide-duration -float 0.0001
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.finder DisableAllAnimations -bool true
killall Dock

echo "✅ macOS 속도 최적화 완료"