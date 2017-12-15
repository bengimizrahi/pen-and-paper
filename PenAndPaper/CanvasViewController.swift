//
//  CanvasViewController.swift
//  PenAndPaper
//
//  Created by Bengi Mizrahi on 15.12.2017.
//  Copyright © 2017 Bengi Mizrahi. All rights reserved.
//

import UIKit

class CanvasViewController: UIViewController {

    var canvasView: CanvasView?

    override func viewDidLoad() {
        super.viewDidLoad()

        canvasView = CanvasView(frame: view.bounds)
        view.addSubview(canvasView!)
    }
}

class CanvasViewPresentationController : UIPresentationController {
    var dimmingView: UIView!

    override init(presentedViewController: UIViewController,
                  presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController,
                   presenting: presentingViewController)
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        dimmingView.alpha = 0.0
        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action:#selector(handleTap(recognizer:))))
    }

    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true, completion: nil)
    }

    override func presentationTransitionWillBegin() {
        containerView?.insertSubview(dimmingView, at: 0)

        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[dv]|", options: [], metrics: nil, views: ["dv": dimmingView]))
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[dv]|", options: [], metrics: nil, views: ["dv": dimmingView]))

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        }, completion: nil)
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        let desiredWidth: CGFloat = 700
        let desiredHeight: CGFloat = 400
        let containerBounds = containerView!.bounds
        let center = CGPoint(x: containerBounds.width / 2.0,
                             y: containerBounds.height / 2.0)
        return CGRect(x: center.x - desiredWidth/2.0,
               y: center.y - desiredHeight/2.0,
               width: desiredWidth, height: desiredHeight)
    }
}

