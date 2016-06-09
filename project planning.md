# Timeline Overview

## Features

* View timeline of posts
* Search all posts by user or hashtag
* Comment on photos
* Push notification for comments on photos

## Black Diamond Features

* Follow users
* User profile page
* Report explicit content
* Add better support for portrait photos

Black Diamonds:

* Search by location

## Views

* Timeline view
    * TableViewController
    * Displays all posts of people I follow
* Search view
    * Segmented control for searching user or 
    * On user search, list 'suggested friends' based on Contacts
* Post detail view
    * Display post and comments
    * Add comment
    * Follow user button
* Add post view
    * Tap to present UIPhotoPickerController
    * Add a Caption

<!-- * Account Setup view
    * TableViewController
    * Appears when I pull a current user's record with no 'display name' property
    * Add photo and display name -->

## Model Objects

<!-- User
- init(record: CKUserRecord)
- recordValue -> CKUserRecord
- displayName: String
- image: UIImage
- friends: [User] -->

Post
- init(record: CKRecord)
- recordValue -> CKRecord
- owner: CKReference (to User)
- caption: String
- image: UIImage
- hashtags: [String]
- comments: [Comment]

Comment
- init(record: CKRecord)
- recordValue -> CKRecord
- owner: CKReference (to User)
- post: CKReference (to Post)
- text: String

## Controllers and Helpers

CoreDataManager
- save() # take insertedObjects and call CloudKitManager.saveChangesToCloudKit(insertedManagedObjectIDs) to save updates
- fetchCloudKitManagedObjects(managedObjectIDs: [NSManagedObjectID]) -> [CloudKitManagedObject]

CloudKitManager

Make each NSOperation subclass a function on the Manager

- publicDatabase
- init # call accountStatusWithCompletionHandler to check for logged in user, respond to success or failure
- saveChangedToCloudKit(insertedObjects: [NSManagedObjectID])
- fetchRecord(query: CKQuery)
- saveRecord
- createFollowSubscription
- createCommentsSubscription
- fetchCurrentUser(completion: (user: User) -> Void)

<!-- UserController
- currentUser # lazy var, loaded from fetchCurentUser
- updateCurrentUser(displayName: String, image: UIImage, completion: () -> Void)
- followUser(user: User, completion: () -> Void) -->

PostController
- createPost(image: UIImage, caption: String) # or (url: NSURL, caption: String) if we just want the image capture to save the photo
- fetchPosts(query: CKQuery, completion: (posts: [Post]) -> Void)
- fetchPosts(searchTerm: String, completion: (posts: [Post]) -> Void)
- fetchTimeline(user: User = UserController.currentUser, completion: (posts: [Post]) -> Void)
- addCommentToPost(comment: String, post: [Post])