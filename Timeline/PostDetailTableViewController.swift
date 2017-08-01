//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Caleb Hicks on 5/25/16.
//  Copyright © 2016 DevMountain. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController, PostActionHandler {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(postCommentsChanged(_:)), name: PostController.PostCommentsChangedNotification, object: nil)
        tableView.reloadData()
        
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostDetailCell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 350.0
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedSectionHeaderHeight = 24.0
    }
    
    // MARK: Actions
    
    func addComment(_ sender: Any) {
        presentCommentAlert()
    }
    
    func share(_ sender: Any) {
        presentActivityViewController()
    }
    
    func toggleFavorite(_ sender: Any) {
        guard let post = post else { return }
        PostController.sharedController.toggleSubscriptionTo(commentsForPost: post)
    }
    
    // MARK: Private
    
    // MARK: UITAbleViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return post?.comments.dropFirst().count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostDetailCell", for: indexPath) as? PostTableViewCell else {
                return UITableViewCell()
            }
            guard let post = post else { return cell }
            cell.post = post
            
            PostController.sharedController.checkSubscriptionTo(commentsForPost: post)
            
            return cell
        } else {
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
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? UITableViewAutomaticDimension : 0.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section != 1 { return nil }
        
        let label = UILabel(frame: .zero)
        label.font = .appTimestampFont
        label.textColor = .appLipstick
        label.text = NSLocalizedString("Comments", comment: "Comments").uppercased()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.addSubview(label)
        label.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 14.0).isActive = true
        label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        return view
    }
    
    // MARK: Alerts, etc.
    
    func presentCommentAlert() {
        
        let alertController = UIAlertController(title: "Add Comment", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            
            textField.placeholder = "Nice shot!"
        }
        
        let addCommentAction = UIAlertAction(title: "Add Comment", style: .default) { (action) in
            
            guard let commentText = alertController.textFields?.first?.text,
                let post = self.post else { return }
            
            PostController.sharedController.addComment(toPost: post, commentText: commentText)
        }
        alertController.addAction(addCommentAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentActivityViewController() {
        
        guard let photo = post?.photo,
            let comment = post?.comments.first else { return }
        
        let text = comment.text
        let activityViewController = UIActivityViewController(activityItems: [photo, text], applicationActivities: nil)
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: Notifications
    
    func postCommentsChanged(_ notification: Notification) {
        guard let notificationPost = notification.object as? Post,
            let post = post, notificationPost === post else { return } // Not our post
        tableView?.reloadData()
    }
    
    // MARK: Properties
    
    var post: Post? {
        didSet {
            tableView?.reloadData()
        }
    }
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
