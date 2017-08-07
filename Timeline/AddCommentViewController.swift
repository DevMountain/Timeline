//
//  AddCommentViewController.swift
//  Timeline
//
//  Created by Andrew R Madsen on 8/3/17.
//  Copyright © 2017 DevMountain. All rights reserved.
//

import UIKit

class AddCommentViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UINavigationBarDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoView.layer.cornerRadius = photoView.frame.width / 2.0
        photoView.layer.masksToBounds = true
        
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        commentsTableView.estimatedRowHeight = 350.0
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        nc.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
        updateViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        commentTextField.text = nil
        //        commentTextField.becomeFirstResponder()
    }
    
    @IBAction func postComment(_ sender: UIButton) {
        commentTextField.text = nil
        commentTextField.resignFirstResponder()
        guard let post = post,
            let comment = commentTextField.text else {
                return
        }
        
        PostController.sharedController.addComment(toPost: post, commentText: comment) { _ in
            DispatchQueue.main.async {
                self.commentsTableView.reloadData()
            }
        }
    }
    
    // UITableViewDataSource/Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post?.comments.dropFirst().count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        guard let post = post else { return cell }
        let comment = post.comments[indexPath.row+1]
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = .appCommentFont
        cell.textLabel?.text = comment.text
        cell.detailTextLabel?.text = dateFormatter.string(from: comment.timestamp)
        cell.detailTextLabel?.font = UIFont.appTimestampFont.withSize(9)
        
        return cell
    }
    
    // UINavigationBarDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    // MARK: Private
    
    private func updateViews() {
        guard let post = post, isViewLoaded else {
            commentsTableView?.reloadData()
            photoView?.image = nil
            captionLabel?.text = nil
            return
        }
        
        photoView.image = post.photo
        captionLabel.text = post.comments.first?.text
        commentsTableView.reloadData()
    }
    
    // Notifications
    
    func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
            let animationCurveRaw = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let animationCurve = UIViewAnimationCurve(rawValue: animationCurveRaw) else {
                return
        }
        
        view.layoutIfNeeded()
        commentBarBottomConstraint.constant = keyboardFrame.size.height
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        
        view.layoutIfNeeded()
        
        UIView.commitAnimations()
    }
    
    func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double,
            let animationCurveRaw = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? Int,
            let animationCurve = UIViewAnimationCurve(rawValue: animationCurveRaw) else {
                return
        }
        
        view.layoutIfNeeded()
        commentBarBottomConstraint.constant = 0
        
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(animationDuration)
        UIView.setAnimationCurve(animationCurve)
        UIView.setAnimationBeginsFromCurrentState(true)
        
        view.layoutIfNeeded()
        
        UIView.commitAnimations()
    }
    
    // MARK: Properties
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentsTableView: UITableView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet var commentBarBottomConstraint: NSLayoutConstraint!
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
