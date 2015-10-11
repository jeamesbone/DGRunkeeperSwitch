//
//  DGRunkeeperSwitch.swift
//  DGRunkeeperSwitchExample
//
//  Created by Danil Gontovnik on 9/3/15.
//  Copyright © 2015 Danil Gontovnik. All rights reserved.
//

import UIKit

// MARK: -
// MARK: DGRunkeeperSwitchRoundedLayer

class DGRunkeeperSwitchRoundedLayer: CALayer {

    override var frame: CGRect {
        didSet { cornerRadius = bounds.height / 2.0 }
    }
    
}

// MARK: -
// MARK: DGRunkeeperSwitch

class DGRunkeeperSwitch: UIControl {

    // MARK: -
    // MARK: Public vars

    var titles: [String] {
        set {
            for title in newValue {
                let titleLabel = UILabel()
                titleLabel.text = title
                titleLabels.append(titleLabel)

                let selectedTitleLabel = UILabel()
                selectedTitleLabel.text = title
                selectedTitleLabels.append(selectedTitleLabel)
            }

            setupViews()
        }
        get {
            return titleLabels.map {
                return $0.text!
            }
        }
    }

    var numberOfSegments: Int {
        get {
            return self.titleLabels.count
        }
    }
    
    private(set) var selectedIndex: Int = 0
    
    var selectedBackgroundInset: CGFloat = 2.0 {
        didSet { setNeedsLayout() }
    }
    
    var selectedBackgroundColor: UIColor! {
        set { selectedBackgroundView.backgroundColor = newValue }
        get { return selectedBackgroundView.backgroundColor }
    }
    
    var titleColor: UIColor! {
        set {
            for label in titleLabels {
                label.textColor = newValue
            }
        }
        get { return titleLabels.first!.textColor }
    }
    
    var selectedTitleColor: UIColor! {
        set {
            for label in selectedTitleLabels {
                label.textColor = newValue
            }
        }
        get { return selectedTitleLabels.first!.textColor }
    }
    
    var titleFont: UIFont! {
        set {
            for label in (titleLabels + selectedTitleLabels) {
                label.font = newValue
            }
        }
        get {
            return titleLabels.first!.font
        }
    }
    
    var animationDuration: NSTimeInterval = 0.3
    var animationSpringDamping: CGFloat = 0.75
    var animationInitialSpringVelocity: CGFloat = 0.0
    
    // MARK: -
    // MARK: Private vars
    
    private var titleLabelsContentView = UIView()
    private var titleLabels = [UILabel]()

    private var selectedTitleLabelsContentView = UIView()
    private var selectedTitleLabels = [UILabel]()

    private(set) var selectedBackgroundView = UIView()
    
    private var titleMaskView: UIView = UIView()
    
    private var tapGesture: UITapGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    
    private var initialSelectedBackgroundViewFrame: CGRect?
    
    // MARK: -
    // MARK: Constructors

    init(titles: [String]) {
        super.init(frame: CGRect.zero)

        self.titles = titles

        setupViews()
    }

    convenience init(leftTitle: String, rightTitle: String) {
        self.init(titles: [leftTitle, rightTitle])
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
    }

    override func prepareForInterfaceBuilder() {
        titles = ["Test1, Test2"]
    }

    private func setupViews() {
        guard numberOfSegments > 0 else { return }

        for label in titleLabels {
            label.lineBreakMode = .ByTruncatingTail
            label.textAlignment = .Center
            titleLabelsContentView.addSubview(label)
        }

        addSubview(titleLabelsContentView)
        
        object_setClass(selectedBackgroundView.layer, DGRunkeeperSwitchRoundedLayer.self)
        addSubview(selectedBackgroundView)

        for label in selectedTitleLabels {
            label.lineBreakMode = .ByTruncatingTail
            label.textAlignment = .Center
            selectedTitleLabelsContentView.addSubview(label)
        }

        addSubview(selectedTitleLabelsContentView)

        object_setClass(titleMaskView.layer, DGRunkeeperSwitchRoundedLayer.self)
        titleMaskView.backgroundColor = .blackColor()
        selectedTitleLabelsContentView.layer.mask = titleMaskView.layer
        
        // Setup defaul colors
        backgroundColor = .blackColor()
        selectedBackgroundColor = .whiteColor()
        titleColor = .whiteColor()
        selectedTitleColor = .blackColor()
        
        // Gestures
        tapGesture = UITapGestureRecognizer(target: self, action: "tapped:")
        addGestureRecognizer(tapGesture)
        
        panGesture = UIPanGestureRecognizer(target: self, action: "pan:")
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
        
        addObserver(self, forKeyPath: "selectedBackgroundView.frame", options: .New, context: nil)
    }
    
    // MARK: -
    // MARK: Destructor
    
    deinit {
        removeObserver(self, forKeyPath: "selectedBackgroundView.frame")
    }
    
    // MARK: -
    // MARK: Observer
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "selectedBackgroundView.frame" {
            titleMaskView.frame = selectedBackgroundView.frame
        }
    }
    
    // MARK: -
    
    override class func layerClass() -> AnyClass {
        return DGRunkeeperSwitchRoundedLayer.self
    }
    
    func tapped(gesture: UITapGestureRecognizer!) {
        let location = gesture.locationInView(self)

        let segmentWidth = bounds.width / CGFloat(numberOfSegments)
        setSelectedIndex(Int(location.x / segmentWidth), animated: true)
    }
    
    func pan(gesture: UIPanGestureRecognizer!) {
        if gesture.state == .Began {
            initialSelectedBackgroundViewFrame = selectedBackgroundView.frame
        } else if gesture.state == .Changed {
            var frame = initialSelectedBackgroundViewFrame!
            frame.origin.x += gesture.translationInView(self).x
            frame.origin.x = max(min(frame.origin.x, bounds.width - selectedBackgroundInset - frame.width), selectedBackgroundInset)
            selectedBackgroundView.frame = frame
        } else if gesture.state == .Ended || gesture.state == .Failed || gesture.state == .Cancelled {
            let velocityX = gesture.velocityInView(self).x

            let segmentWidth = bounds.width / CGFloat(numberOfSegments)
            let touchedIndex = Int(selectedBackgroundView.center.x / segmentWidth)

            if (touchedIndex != selectedIndex) {
                setSelectedIndex(touchedIndex, animated: true)
            } else {
                if velocityX > 500.0 {
                    let newSelectedIndex = min(numberOfSegments - 1, selectedIndex + 1)
                    setSelectedIndex(newSelectedIndex, animated: true)
                } else if velocityX < -500.0 {
                    let newSelectedIndex = max(0, selectedIndex - 1)
                    setSelectedIndex(newSelectedIndex, animated: true)
                } else {
                    setSelectedIndex(touchedIndex, animated: true)
                }
            }
        }
    }
    
    func setSelectedIndex(selectedIndex: Int, animated: Bool) {
        self.selectedIndex = selectedIndex

        if animated {
            UIView.animateWithDuration(animationDuration,
                delay: 0.0,
                usingSpringWithDamping: animationSpringDamping,
                initialSpringVelocity: animationInitialSpringVelocity,
                options: [UIViewAnimationOptions.BeginFromCurrentState, UIViewAnimationOptions.CurveEaseOut],
                animations: {
                    self.layoutSubviews()
                },
                completion: { (finished) -> Void in
                    if finished && self.selectedIndex == selectedIndex {
                        self.sendActionsForControlEvents(.ValueChanged)
                    }
            })
        } else {
            layoutSubviews()
            if (self.selectedIndex == selectedIndex) {
                sendActionsForControlEvents(.ValueChanged)
            }
        }
    }
    
    // MARK: -
    // MARK: Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()

        guard numberOfSegments > 0 else { return }

        let selectedBackgroundWidth = bounds.width / CGFloat(numberOfSegments) - selectedBackgroundInset * 2.0
        selectedBackgroundView.frame = CGRect(x: selectedBackgroundInset + CGFloat(selectedIndex) * (selectedBackgroundWidth + selectedBackgroundInset * 2.0), y: selectedBackgroundInset, width: selectedBackgroundWidth, height: bounds.height - selectedBackgroundInset * 2.0)
        
        (titleLabelsContentView.frame, selectedTitleLabelsContentView.frame) = (bounds, bounds)
        
        let titleLabelMaxWidth = selectedBackgroundWidth
        let titleLabelMaxHeight = bounds.height - selectedBackgroundInset * 2.0

        for (index, label) in titleLabels.enumerate() {
            let labelSize = CGSize(width: titleLabelMaxWidth, height: titleLabelMaxHeight)

            let x = floor((bounds.width / CGFloat(numberOfSegments)) * CGFloat(index))
            let labelOrigin = CGPoint(x: x, y: floor((bounds.height - labelSize.height) / 2.0))
            let labelFrame = CGRect(origin: labelOrigin, size: labelSize)

            label.frame = labelFrame
            selectedTitleLabels[index].frame = labelFrame
        }
    }
    
}

// MARK: -
// MARK: UIGestureRecognizer Delegate

extension DGRunkeeperSwitch: UIGestureRecognizerDelegate {
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            return selectedBackgroundView.frame.contains(gestureRecognizer.locationInView(self))
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
}
