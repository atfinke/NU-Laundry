//
//  MachineView.swift
//  NU Laundry
//
//  Created by Andrew Finke on 9/29/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class ProgressView: UIView {

    // MARK: - Properties

    private var circleLayer = CAShapeLayer()
    private let progressWidth: CGFloat = 5.0
    private var currentEndAngle: CGFloat = 0.0

    // MARK: - Initalization

    override init(frame: CGRect) {
        super.init(frame: frame)

        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = progressWidth

        circleLayer.strokeEnd = 0.0
        circleLayer.strokeColor = UIColor.white.cgColor
        //        circleLayer.strokeColor = UIColor(displayP3Red: 52.0/255.0,
        //                                          green: 124.0/255.0,
        //                                          blue: 237.0/255.0,
        //                                          alpha: 1.0).cgColor

        layer.addSublayer(circleLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animation

    func updated(progress: CGFloat, animated: Bool) {

        if let presentationLayer = circleLayer.presentation() {
            let currentValue = presentationLayer.strokeEnd
            circleLayer.removeAllAnimations()
            circleLayer.strokeEnd = currentValue
        }

        let startAngle = -CGFloat.pi / 2
        let previousEndAngle = currentEndAngle
        let newEndAngle = startAngle + progress * CGFloat.pi * 2
        currentEndAngle = newEndAngle

        let circleCenter = CGPoint(x: frame.size.width / 2.0,
                                   y: frame.size.height / 2.0)

        let circlePath = UIBezierPath(arcCenter: circleCenter,
                                      radius: (frame.size.width - progressWidth)/2 ,
                                      startAngle: startAngle,
                                      endAngle: newEndAngle,
                                      clockwise: true)

        circleLayer.path = circlePath.cgPath

        guard animated else {
            circleLayer.strokeEnd = 1.0
            return
        }

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 5.0

        let diff = ((previousEndAngle - startAngle) / (newEndAngle - startAngle))
        animation.fromValue = circleLayer.strokeEnd * diff
        animation.toValue = 1

        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        circleLayer.strokeEnd = 1.0
        circleLayer.add(animation, forKey: "progress")
    }

}

class MachineView: UIView {

    var machine: Machine? = nil {
        didSet {
            updatedMachine()
        }
    }

    let titleLabel = UILabel()
    let detailLabel = UILabel()

    let noDetailTitleLabel = UILabel()

    var progressView: ProgressView!


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        noDetailTitleLabel.frame = frame
        titleLabel.frame = CGRect(x: 0, y: 10, width: frame.width, height: frame.height / 2)
        detailLabel.frame = CGRect(x: 0, y: 29.5, width: frame.width, height: frame.height / 2)

        progressView = ProgressView(frame: frame)
        addSubview(progressView)

        noDetailTitleLabel.textAlignment = .center
        noDetailTitleLabel.baselineAdjustment = .alignCenters
        noDetailTitleLabel.textColor = UIColor.white
        noDetailTitleLabel.font = UIFont.systemFont(ofSize: 25, weight: .semibold)
        addSubview(noDetailTitleLabel)

        titleLabel.textAlignment = .center
        titleLabel.baselineAdjustment = .alignBaselines
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.systemFont(ofSize: 25, weight: .semibold)
        addSubview(titleLabel)

        detailLabel.textAlignment = .center
        detailLabel.textColor = UIColor.white
        detailLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        addSubview(detailLabel)

        layer.cornerRadius = frame.width / 2
    }

    private func updatedMachine() {
        guard let machine = machine else { return }

        titleLabel.text = machine.number.description
        noDetailTitleLabel.text = machine.number.description

        progressView.isHidden = true
        titleLabel.isHidden = true
        detailLabel.isHidden = true
        noDetailTitleLabel.isHidden = true

        switch machine.status {
        case .active(let time, let progress):
            titleLabel.isHidden = false
            detailLabel.isHidden = false
            progressView.isHidden = false

            detailLabel.text = "\(time) MIN"
            progressView.updated(progress: CGFloat(progress), animated: true)
            backgroundColor = UIColor(displayP3Red: 230.0/255.0,
                                      green: 50.0/255.0,
                                      blue: 35.0/255.0,
                                      alpha: 1.0)
        case .available:
            noDetailTitleLabel.isHidden = false
            progressView.updated(progress: 0.0, animated: false)

            backgroundColor = UIColor(displayP3Red: 67.0/255.0,
                                      green: 144.0/255.0,
                                      blue: 78.0/255.0,
                                      alpha: 1.0)

        case .cycleEnded(let time):
            titleLabel.isHidden = false
            detailLabel.isHidden = false

            detailLabel.text = "\(time) MIN"
            progressView.updated(progress: 1.0, animated: true)
            backgroundColor = UIColor.orange
        case .outOfService:
            noDetailTitleLabel.isHidden = false
            progressView.updated(progress: 0.0, animated: false)
            backgroundColor = UIColor.black
        case .extendedCycle(let time):
            titleLabel.isHidden = false
            detailLabel.isHidden = false

            detailLabel.text = "\(time) MIN"
            progressView.updated(progress: 1.0, animated: true)
            backgroundColor = UIColor.red
        case .unknown:
            noDetailTitleLabel.isHidden = false
            progressView.updated(progress: 0.0, animated: false)
            backgroundColor = UIColor.lightGray
        }
    }
}
