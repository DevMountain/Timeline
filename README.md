# Timeline

### Level 3

Timeline is a simple photo sharing service. Students will bring in many concepts that they have learned, and add more complex data modeling, Image Picker, CloudKit, and protocol-oriented programming to make a Capstone Level project spanning multiple days and concepts.

Most concepts will be covered during class, others are introduced during the project. Not every instruction will outline each line of code to write, but lead the student to the solution.

Students who complete this project independently are able to:

#### Part One - Project Planning, Model Objects, and Controllers

* follow a project planning framework to build a development plan
* follow a project planning framework to prioritize and manage project progress
* implement basic data model
* use staged data to prototype features

#### Part Two - Apple View Controllers, Search Controller, Container Views

* implement search using the system search controller
* use the image picker controller and activity controller
* use container views to abstract shared functionality into a single view controller

#### Part Three - Basic CloudKit: CloudKitManager,

* Check CloudKit availability
* Save data to CloudKit
* Fetch data from CloudKit
* Query data from CloudKit

#### Part Four - Intermediate CloudKit: Subscriptions, Push Notifications, Automatic Sync

* use subscriptions to generate push notifications
* use push notifications to run a push based sync engine

## Part One - Project Planning, Model Objects, and Controllers

* follow a project planning framework to build a development plan
* follow a project planning framework to prioritize and manage project progress
* implement basic data model
* use staged data to prototype features

Follow the development plan included with the project to build out the basic view hierarchy, basic implementation of local model objects, model object controllers, and helper classes. Build staged data to lay a strong foundation for the rest of the app.

### View Hierarchy

Implement the view hierarchy in Storyboards. The app will have a tab bar controller as the initial controller. The tab bar controller will have two tabs.

The first is a navigation controller that has a PostListTableViewController that will display the list of posts, and will also use a UISearchController to display search results. Both the PostListTableViewController and the SearchResultsTableViewController (from the UISearchController) will display a list of `Post` objects and segue to a `Post` detail view.

The second tab is a separate navigation controller that will hold a view controller to add new posts.

1. Create a `UITabBarController` as your initial view. Add a `UITableViewController` Timeline scene, embed it in a `UINavigationController`, make the navigation controller your first tab in the tab bar controller. (hint: control + drag from the tab bar controller to the navigation controller and select "view controllers" under the "Relationship Segue" section in the contextual menu)
2. Make the `UITableViewController` from step 1 a `PostListTableViewController` Cocoa Touch file subclass of `UITableViewController` and assign it to the Timeline scene
3. Add a `UITableViewController` Post Detail scene, add a segue to it from the `PostListTableViewController` scene
4. Add a `PostDetailTableViewController` subclass of `UITableViewController` and assign it to the Post Detail scene from step 3.
5. Add a `UITableViewController` Add Post scene, embed it into a `UINavigationController`. Make this navigation controller your second tab in the tab bar controller.
6. Add a `AddPostTableViewController` subclass of `UITableViewController` and assign it to the Add Post scene from step 5.
7. Add a `UITableViewcontroller` Search Results scene. It does not need a segue to any other view controller.
* note: You will implement this scene in Part 2 when setting up the `UISearchController` on the Search scene
8. Add a `SearchResultsTableViewController` subclass of `UITableViewController` and assign it to the Search Results scene.

### Implement Model

Timeline will use a simple, non-persistent data model to locally represent data stored on CloudKit.

Start by creating model objects. You will want to save `Post` objects that hold the image data, and `Comment` objects that hold text. A `Post` should own an array of `Comment` objects.

#### Post

Create a `Post` model object that will hold image data and comments.

1. Add a new `Post` class to your project.
2. Add a `photoData` property of type `Data?`, a `timestamp` `Date` property, and a `comments` property of type `[Comment]`.
3. Add a computed property, `photo` that returns a `UIImage` initialized using the data in `photoData`.
4. Add an initializer that accepts photoData, timestamp, and comments array. Provide default values for the `timestamp` and `comments` arguments, so they can be ommitted if desired.

#### Comment

Create a `Comment` model object that will hold user-submitted text comments for a specific `Post`.

1. Add a new `Comment` class to your project.
2. Add a `text` property of type `String`, a `timestamp` `Date` property, and a `post` property of type `Post`.
3. Add an initializer that accepts text, timestamp, and a post. Provide a default values for the `timestamp` argument, so it can be ommitted if desired.

### Model Object Controller

Add and implement the `PostController` class that will be used for CRUD operations.

1. Add a new `PostController` class file.
2. Add a `sharedController` singleton property.
3. Add a `posts` property.
4. Add a `addComment(toPost: ...)` function that takes a `text` parameter as a `String`, and a `Post` parameter. This should return a Comment object in a completion closure.
5. Add a `createPostWith(image: ...)` function that takes an image parameter as a `UIImage` and a caption as a `String`. This should return a Post object in a completion closure.
6. Implement the `createPostWith(image: ...)` function to initialize a `Post` with the image and a `Comment` with the caption text. Note: use the `addComment(toPost: ...)` function you just created to call the appropriate `Comment` initializer and adds the comment to the appropriate post.

### Wire Up Views

#### Timeline Scene - Post List Table View Controller

Implement the Post List Table View Controller. You will use a similar cell to display posts in multiple scenes in your application. Create a custom `PostTableViewCell` that can be reused in different scenes.

1. Implement the scene in Interface Builder by creating a custom cell with an image view that fills the cell.
2. Create a `PostTableViewCell` class, add a `post` variable, and implement an `updateViews` function to the `PostTableViewCell` to update the image view with the `Post`'s photo. Call the function in the didSet of the `post` variable'
3. Choose a height that will be used for your image cells. To avoid worrying about resizing images or dynamic cell heights, you may want to use a consistent height for all of the image views in the app.
4. Implement the `UITableViewDataSource` functions
* note: The final app does not need to support any editing styles, but you may want to include support for editing while developing early stages of the app.
5. Implement the `prepare(for segue: ...)` function to check the segue identifier, capture the detail view controller, index path, selected post, and assign the selected post to the detail view controller.
* note: You may need to quickly add a `post` property to the `PostDetailTableViewController`.

#### Post Detail Scene

Implement the Post Detail View Controller. This scene will be used for viewing post images and comments. Users will also have the option to add a comment, share the image, or follow the user that created the post.

Use the table view's header view to display the photo and a toolbar that allows the user to comment, share, or follow. Use the table view cells to display comments.

1. Add a vertical `UIStackView` to the Header of the table view. Add a `UIImageView` and a horizontal `UIStackView` to the stack view. Add 'Comment', 'Share', and 'Follow Post' `UIButton`s to the horizontal stack view. Set the horizontal hugging priority of the center button (Share) to 249 to distribute the buttons correctly.
2. Set up your constraints so that the image view is the height you chose previously for displaying images within your app.
3. Update the cell to support comments that span multiple lines without truncating them. Set the `UITableViewCell` to the subtitle style. Set the number of lines to zero. Implement dynamic heights by setting the `tableView.rowHeight` and `tableView.estimatedRowHeight` in the `viewDidLoad`.
4. Add an `updateViews` function that will update the scene with the details of the post. Implement the function by setting the `imageView.image` and reloading the table view if needed.
5. Implement the `UITableViewDataSource` functions.
* note: The final app does not need to support any editing styles, but you may want to include support for editing while developing early stages of the app.
6. Add an IBAction for the 'Comment' button. Implement the IBAction by presenting a `UIAlertController` with a text field, a Cancel action, and an 'OK' action. Implement the 'OK' action to initialize a new `Comment` via the `PostController` and reload the table view to display it.
* note: Do not create a new `Comment` if the user has not added text.
7. Add an IBAction for the 'Share' and 'Follow' buttons. You will implement these two actions in future steps.

#### Add Post Scenes

Implement the Add Post Table View Controller. You will use a static table view to create a simple form for adding a new post. Use three sections for the form:

Section 1: Large button to select an image, and a `UIImageView` to display the selected image
Section 2: Caption text field
Section 3: Add Post button

Until you implement the `UIImagePickerController`, you will use a staged static image to add new posts.

1. Assign the table view to use static cells. Adopt the 'Grouped' cell style. Add three sections.
2. Build the first section by creating a tall image selection/preview cell. Add a 'Select Image' `UIButton` that fills the cell. Add an empty `UIImageView` that also fills the cell. Make sure that the button is on top of the image view so it can properly recognize tap events.
3. Build the second section by adding a `UITextField` that fills the cell. Assign placeholder text so the user recognizes what the text field is for.
4. Build the third section by adding a 'Add Post' `UIButton` that fills the cell.
5. Add an IBAction to the 'Select Image' `UIButton` that assigns a static image to the image view (add a sample image to the Assets.xcassets that you can use for prototyping this feature), and removes the title text from the button.
* note: It is important to remove the title text so that the user no longer sees that a button is there, but do not remove the entire button, that way the user can tap again to select a different image.
6. Add an IBAction to the 'Add Post' `UIButton` that checks for an `image` and `caption`. If there is an `image` and a `caption`, use the `PostController` to create a new `Post` and dismiss the view controller. If either the image or a caption is missing, present an alert directing the user to check their information and try again.
* note: the process to dismiss this view controller will be different from what we have previously covered.
7. Add a 'Cancel' `UIBarButtonItem` as the left bar button item. Implement the IBAction to dismiss the view.

#### A Note on Reusable Code

Consider that this Photo Selection functionality could be useful in different views and in different applications. New developers will be tempted to copy and paste the functionality wherever it is needed. That amount of repetition should give you pause. _Don't repeat yourself_ (DRY) is a shared value among skilled software developers.

Avoiding repetition is an important way to become a better developer and maintain sanity when building larger applications.

Imagine a scenario where you have three classes with similar functionality. Each time you fix a bug or add a feature to any of those classes, you must go and repeat that in all three places. This commonly leads to differences, which leads to bugs.

You will refactor the Photo Selection functionality (selecting and assigning an image) into a reusable child view controller in Part 2.

### Polish Rough Edges

At this point you should be able view added post images in the Timeline Post List scene, add new `Post` objects from the Add Post Scene, add new `Comment` objects from the Post Detail Scene, and persist and use user profile information provided by the current user.

Use the app and polish any rough edges. Check table view cell selection. Check text fields. Check proper view hierarchy and navigation models.

### Black Diamonds

* Review the README instructions and solution code for clarity and functionality, submit a GitHub pull request with suggested changes.
* Provide feedback on the expectations for Part One to a mentor or instructor.

## Part Two - Search Controller, Container Views, Apple View Controllers

* implement search using the system search controller
* use the image picker controller and activity controller
* use container views to abstract shared functionality into a single view controller

Add and implement search functionality to the search view. Implement the Image Picker Controller on the Add Post scene. Decrease the amount of repeated code by refactoring the similar functionality in the Add Post scenes into a child view controller that is used in both classes.

### Search Controller

Build functionality that will allow the user to search for posts with comments that have specific text in them. For example, if a user creates a `Post` with a photo of a waterfall, and there are comments that mention the waterfall, the user should be able to search the Timeline view for the term 'water' and filter down to that post (and any others with water in the comments).

#### Update the Model

Add a `SearchableRecord` protocol that requires a `matchesSearchTerm` function. Update the `Post` and `Comment` objects to conform to the protocol.

1. Add a new `SearchableRecord.swift` file.
2. Define a `SearchableRecord` protocol with a required `matches(searchTerm: String)` function that takes a `searchTerm` parameter as a `String` and returns a `Bool`.

Consider how each model object will match to a specific search term. What searchable text is there on a `Comment`? What searchable text is there on a `Post`?

3. Update the `Comment` class to conform to the `SearchableRecord` protocol. Return `true` if `text` contains the search term, otherwise return `false`.
4. Update the `Post` class to conform to the `SearchableRecord` protocol. Return `true` if any of the `Post` `comments` match, otherwise return `false`.

Use a Playground to test your `SearchableRecord` and `matches(searchTerm: String)` functionality and understand what you are implementing.

#### Search Results Controller

Search controllers typically have two views: a list view, and a search result view that displays the filtered results. The list view holds the search bar. When the user begins typing in the search bar, the `UISSearchController` presents a search results view. Your list view must conform to the `SearchResultsUpdating` protocol function, which implements updates to the results view.

Understanding Search Controllers requires you to understand that the main view controller can (and must) implement methods that handle what is being displayed on another view controller. The results controller must also implement a way to communicate back to the main list view controller to notify it of events. This is a two way relationship with communication happening in both directions.

1. Create a `SearchResultsTableViewController` subclass of `UITableViewController` and assign it to the scene in Interface Builder.
2. Add a `resultsArray` property that contains a list of `SearchableRecords`
3. Implement the `UITableViewDataSource` functions to display the search results.   
* note: For now you will only display `Post` objects as a result of a search. Use the `PostTableViewCell` to do so.

#### Update PostListTableViewController

1. In the PostListTableViewController.swift, add a function `setUpSearchController` that captures the `resultsController` from the Storyboard, instantiates the `UISearchController`, sets the `searchResultsUpdater` to self, and adds the `searchController`'s `searchBar` as the table's header view.
2. Implement the `UISearchResultsUpdating` protocol `updateSearchResults(for searchController: UISearchController)` function. The function should capture the `resultsViewController` and the search text from the `searchController`'s `searchBar`, filter the local `posts` array for posts that match, assign the filtered results to the `resultsViewController`'s `resultsArray`, and reload the `resultsViewController`'s `tableView`.
* note: Consider the communication that is happening here between two separate view controllers. Be sure that you understand this relationship.

##### Segue to Post Detail View

Remember that even though the Timeline view and the Search Results view are displaying similar cells and model objects, you are working with separate view controllers with separate cells and instances of table views.

The segue from a `Post` should take the user to the Post Detail scene, regardless of whether that is from the Timeline view or the Search Results view.

To do so, implement the `UITableViewDelegate` `didSelectRowAt indexPath` function on the Search Results scene to manually call the `toPostDetail` segue _from the Search scene_.

1. Adopt the `UITableViewDelegate` on the Search Results scene and add the `didSelectRowAt indexPath` delegate function. Implement the function by capturing the sending cell and telling the Search Result scene's `presentingViewController` to `performSegue(withIdentifier: String...)` and send the selected cell so that the Search scene can get the selected `Post`.
* note: Every view controller class has an optional `presentingViewController` reference to the view controller that presented it. In this case, the presenting view controller of the Search Results scene is the Timeline scene. So this step will manually call the `performSegueWithIdentifier` on the Search scene.
2. Update the `performSegue(withIdentifier: String...)` function on the Search Scene to capture and segue to the Post Detail scene with the correct post. Try to do so without looking at the solution code.
* note: You must check if the `tableView` can get an `indexPath` for the sender. If it can, that means that the cell was from the Search scene's `tableView`. If it can't, that means the cell is from the Search Result scene's `tableView` and that the user tapped a search result. If that is the case, capture the `Post` from the `resultsArray` on the `searchResultscontroller`.
* note: You can access the `searchResultsController` by calling `(searchController.searchResultsController as? SearchResultsTableViewController)`

Try to work through the Search segue without looking at the solution code. Understanding this pattern will solidify your understanding of many object-oriented programming patterns.


### Image Picker Controller

#### Photo Select Child Scene

Implement the Image Picker Controller in place of the prototype functionality you built previously.

1. Update the 'Select Image' IBAction to present a `UIImagePickerController`. Give the user the option to select from their Photo Library or from the device's camera if their device has one.
2. Implement the `UIImagePickerControllerDelegate` function to capture the selected image and assign it to the image view.

### Reduce Code Repetition

Refactor the photo selection functionality from the Add Post scene into a child view controller.

Child view controllers control views that are a subview of another view controller. It is a great way to encapsulate functionality into one class that can be reused in multiple places. This is a great tool for any time you want a similar view to be present in multiple places.

In this instance, you will put 'Select Photo' button, the image view, and the code that presents and handles the `UIImagePickerController` into a `PhotoSelectorViewController` class. You will also define a protocol for the `PhotoSelectorViewController` class to communicate with it's parent view controller.

#### Container View and Embed Segues

Use a container view to embed a child view controller into the Add Post scene.

>Container View defines a region within a view controller's view subgraph that can include a child view controller. Create an embed segue from the container view to the child view controller in the storyboard.

1. Open `Main.storyboard` to your Add Post scene.
2. Add a new section to the static table view to build the Container View to embed the child view controller.
3. Search for Container View in the Object Library and add it to the newly created table view cell.
* note: The Container View object will come with a view controller scene. You can use the included scene, or replace it with another scene. For now, use the included scene.
4. Set up contraints so that the Container View fills the entire cell.
5. Move or copy the Image View and 'Select Photo' button to the container view controller.
6. Create a new `PhotoSelectViewController` file as a subclass of `UIViewController` and assign the class to the scene in Interface Builder.
7. Create the necessary IBOutlets and IBActions, and migrate your Photo Picker code from the Add Post view controller class. Delete the old code from the Add Post view controller class.
8. Repeat the above steps for the Add Post scene. Instead of keeping the included child view controller from the Container View object, delete it, and add an 'Embed' segue from the container view to the scene you set up for the Add Post scene.

You now have two views that reference the same scene as a child view controller. This scene and accompanying class can now be used in both places, eliminating the need for code duplication.

#### Child View Controller Delegate

Your child view controller needs a way to communicate events to it's parent view controller. This is most commonly done through delegation. Define a child view controller delegate, adopt it in the parent view controller, and set up the relationship via the embed segue.

1. Define a new `PhotoSelectViewControllerDelegate` protocol in the `PhotoSelectViewController` file with a required `photoSelectViewControllerSelected(image: UIImage)` function that takes a `UIImage` parameter to pass the image that was selected.
* note: This function will tell the assigned delegate (the parent view controller, in this example) what image the user selected.
2. Add a weak optional delegate property.
3. Call the delegate function in the `didFinishPickingMediaWithInfo` function, passing the selected media to the delegate.
4. Adopt the `PhotoSelectViewControllerDelegate` protocol in the Add Post class file, implement the `photoSelectViewControllerSelectedImage` function to capture a reference to the selected image.
* note: In the Add Post scene, you will use that captured reference to create a new post.

Note the use of the delegate pattern. You have encapsulated the Photo Selection workflow in one class, but by implementing the delegate pattern,  each parent view controller can implement it's own response to when a photo was selected.

You have declared a protocol, adopted the protocol, but you now must assign the delegate property on the instance of the child view controller so that the `PhotoSelectViewController` can communicate with it's parent view controller. This is done by using the embed segue, which is called when the Container View is initialized from the Storyboard, which occurs when the view loads.

1. Assign segue identifiers to the embed segues in the Storyboard file
2. Update the `prepare(forSegue: ...)` function in the Add Post scene to check for the segue identifier, capture the `destinationViewController` as a `PhotoSelectViewController`, and assign `self` as the child view controller's delegate.

### Post Detail View Controller Share Sheet

Use the `UIActivityController` class to present a share sheet from the Post Detail view. Share the image and the text of the first comment.

1. Add an IBAction from the Share button in your `PostDetailTableViewController`.
2. Initialize a `UIActivityController` with the `Post`'s image and the text of the first comment as the shareable objects.
3. Present the `UIActivityController`.

### Black Diamonds:

* Some apps will save photos taken or processed in their app in a custom Album in the user's Camera Roll. Add this feature.
* Review the README instructions and solution code for clarity and functionality, submit a GitHub pull request with suggested changes.
* Provide feedback on the expectations for Part Two to a mentor or instructor.


## Part Three - Basic CloudKit: CloudKitManager, CloudKitSyncable, Manual Sync

* Check CloudKit availability
* Save data to CloudKit
* Fetch data from CloudKit

Following some of the best practices in the CloudKit documentation, add CloudKit to your project as a backend syncing engine for posts and comments. Check for CloudKit availability, save new posts and comments to CloudKit, and fetch posts and comments from CloudKit.

When you finish this part, the app will support syncing photos, posts, and comments from the device to CloudKit, and pulling new photos, posts, and comments from CloudKit. When new posts or comments are fetched from CloudKit, they will be turned into model objects, and the Fetched Results Controllers will automatically update the user interface with the new data.

You will implement push notifications, subscriptions, and basic automatic sync functionality in Part Four.

### CloudKit Manager

Add a CloudKit Manager that abstracts your CloudKit code into a single helper class that implements basic CloudKit functionality. You will not necessarily use all of the `CloudKitManager` functionality in this application, but this will be a great reusable class for CloudKit applications that you build in the future.

1. Add a `CloudKitManager` Swift file.
2. Copy the class in the CloudKitManager.swift file in this repository and paste it in your CloudKitManager.swift file

### Update Post for CloudKit functionality

1. Add a computed property `recordType` and return the type you would like used to identify 'Post' objects in CloudKit. (Note: this is simply so that you don't have to write `Post.typeKey` a bunch of times within the scope of this class, and instead simply write `recordType`.)

2. To save your photo to CloudKit, it must be stored as a `CKAsset`. `CKAsset`s must be initialized with a file path URL. In order to accomplish this, you need to create a variable `temporaryPhotoURL` that copies the contents of the `photoData: NSData?` property to a file in a temporary directory and returns the URL to the file. It looks like this:

```swift
private var temporaryPhotoURL: URL {

// Must write to temporary directory to be able to pass image file path url to CKAsset

let temporaryDirectory = NSTemporaryDirectory()
let temporaryDirectoryURL = URL(fileURLWithPath: temporaryDirectory)
let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

try? photoData?.write(to: fileURL, options: [.atomic])

return fileURL
}
```

3. Add a `cloudKitRecordID` property of type `CKRecordID?`. This will allow us to create a `CKReference` to the post from its comments.
4. Add `cloudKitRecord` computed property that returns `CKRecord`. When you initialize the `CKRecord`, check if the post's `cloudKitRecordID` has a value. Use that as the records `CKRecordID`, otherwise, just create a `CKRecordID` with a new UUID string. The record should include the `timestamp` and a `CKAsset` that points to a URL of the photo data.
* note: `CKAsset` is initialized with a URL. When creating a `CKAsset` on the local device, you initialize it with a URL to a local file path where the photo is located on disk. When you save a `CKAsset`, the data at that file path is uploaded to CloudKit. When you pull a `CKAsset` from CloudKit, the URL will point to the remotely stored data.

5. Add the required convenience initializer `init?(record: CKRecord)`.
6. Implement the convenience initializer by guarding for the timestamp and photo data, calling the designated (memberwise) initializer, then setting the `cloudKitRecordID` property.

### Update Comment for CloudKit Functionality

1. Add a computed property `recordType` and return the type you would like used to identify 'Comment' objects in CloudKit. (Note: this is simply so that you don't have to write `Comment.typeKey` a bunch of times within the scope of this class, and instead simply write `recordType`.)
2. Add `cloudKitRecord` computed property that returns `CKRecord`. When you initialize the `CKRecord`, check if the comment's `cloudKitRecordID` has a value. Use that as the records `CKRecordID`, otherwise, just create a `CKRecordID` with a new UUID string. The record should include the `timestamp`, `text`, and a `CKReference` to the `Comment`'s `Post`'s `CKRecord`.
* note: You will need to guard for the `Comment`'s `Post` and the `Post`'s `cloudKitRecord` to be able to initialize the `CKReference`.

3. Add the required convenience initializer `init?(record: CKRecord)`.
4. Implement the convenience initializer by guarding for the timestamp and post reference, calling the designated (memberwise) initializer, then setting the `cloudKitRecordID` property.

Remember that a `Comment` should not exist without a `Post`. When a `Comment` is created from a `CKRecord`, you will also need to set the new comment's `Post` property. Consider how you would approach this. We will address it in the next section.

### Update the Post Controller for CloudKit functionality

#### Saving Records

Update the `PostController` to support pushing and pulling data from CloudKit using the `CloudKitManager` class.

1. Update the `createPost` function to create a `CKRecord` using the computed property you created, and call the `cloudKitManager.saveRecord` function. Use the completion closure to set the `cloudKitRecordID` property on the `Post` to persist the `CKRecordID`. Without doing this, the references on this post's comments will not work.
2. Update the `addCommentToPost` function to to create a `CKRecord` using the computed property you created, and call the `cloudKitManager.saveRecord` function. Use the completion closure to set the `cloudKitRecordID` property on the `Comment` to persist the `CKRecordID`.

At this point, each new `Post` or `Comment` should be pushed to CloudKit when new instances are created from the Add Post or Post Detail scenes.

#### Fetching Records

There are a number of approaches you could take to fetching new records. For Timeline, we will simply be fetching (or re-fetching, after the initial fetch) all the posts at once. Note that while we are doing it in this project, it is not an optimal solution. We are doing it here so you can master the basics of CloudKit first.

Note: If you want the challenge, you could modify the following functions so that you only fetch the records you don't already have on the device. **This is not required, and is a Black Diamond**

##### Fetching Comments

We're going to create a function that will allow us to fetch all the comments for a specific post we give it.

1. Add a fetchCommentsFor(post: Post, ...) function that has a completion closure. Give the completion a default value of an empty closure.
2. Create a constant that holds a `CKReference` with the value of the Post's `cloudKitRecord` or `cloudKitRecordID` (depending on which CKReference initializer you use. Either should work fine)
3. Because we don't want to fetch every comment ever created, we must use a different `NSPredicate` than the default one. Create a predicate that checks the value of the correct field that corresponds to the post `CKReference` on the Comment record against the `CKReference` you created in the last step.
4. Call the `CloudKitManager.shared.fetchRecordsWithType` function, making sure to pass in the predicate you just created. In the completion closure of the function, follow the common pattern of checking for errors, making sure the records exist, then create an array of Comment objects however you prefer.
5. Set the value of the array of comments in the post passed into this function to the comments you just initialized in the previous step.


##### Fetching Posts

1. Add a `fetchPosts` function that has a completion closure. Give the completion a default value of an empty closure.
2. Call the `CloudKitManager.shared.fetchRecordsWithType` function. Use the function's completion block to check for errors, then initialize an array of Posts from the records returned.
3. Loop through the array of post and call the `fetchCommentsFor(post: Post...)` you made in the last section. Note: In order for this loop to work, you will need to use a dispatch group to make sure that each call of the  `fetchCommentsFor(post: Post...)` comes back and completes before moving on.
4. In the dispatch group's `notify` function, set the value of the `PostController`'s `posts` array to the posts you just initialized, and call completion.


#### NotificationCenter

1. Add static `PostsChangedNotification` and `PostCommentsChangedNotification` string properties.
2. Add a `didSet` property observer to the `posts` property.
3. In the `didSet`, post a `PostController.PostsChangedNotification` `NSNotification.Name` to notify any interested listeners that the array of posts has changed. Post the notification on the main queue since observers will be updating UI in response, and that can only be done on the main queue.
4. In Post.swift, create a `didSet` property observer to the `comments` property.
5. Post a `PostController.PostCommentsChangedNotification`. in the `didSet` created in the previous step. Again this must be done on the main queue. Use the `Post` whose comments changed as the object of the notification. (Since you are in the Post class, you would do that by saying `self`)

#### Update the Post List Table View Controller

Update the Post List view to support Pull to Refresh to initiate a sync operation.

1. Add a new function to request a full sync operation that takes an optional completion closure. Implement the function by turning on the network activity indicator, calling the `performFullSync` function on the `PostController`, and turning off the network activity indicator in the completion.
2. Call the function in the `viewDidLoad` lifecycle function to initiate a full sync when the user first opens the application.
3. Add and implement a `UIRefreshControl` IBAction that uses the sync function.
4. In `viewDidLoad()`, start observing the `PostController.PostsChangedNotification`. In your observation method, reload the table view.

#### Update the Post Detail Table View Controller

1. In `viewDidLoad()`, start observing the `PostController.PostCommentsChangedNotification`.
2. In your observation method, check that the notification's object is the post whose detail is being displayed, and if so, reload the table view.

#### Check Functionality

At this point the app should support basic push and fetch syncing from CloudKit. Use your Simulator and your Device to create new `Post` and `Comment` objects. Use the Refresh Control to initiate new sync operations between the two instances of your app. Check for and fix any bugs.

## Part Four - Intermediate CloudKit: Subscriptions, Push Notifications

* Use subscriptions to generate push notifications
* Use push notifications to run a push based sync engine

Implement Subscriptions and push notifications to create a simple automatic sync engine. Add support for subscribing to new `Post` records and for subscribing to new `Comment` records on followed `Posts`s. Request permission for remote notifications. Respond to remote notifications by initializing the new `Post` or `Comment` with the new data.

When you finish this part, the app will support syncing photos, posts, and comments from remote notifications generated when new records are created in CloudKit. This will allow all devices that have given permission for remote notifications the ability to sync new posts and comments automatically. When new posts or comments are created in CloudKit, they will be serialized into model objects, and the UI will update with the new data.


### Add Subscription Support to the CloudKitManager

Build functionality into your `CloudKitManager` that can be used to manage subscriptions and push notifications. Add support for adding a subscription, fetching a single subscription, fetching all subscriptions, and deleting a subscription.

### PostController Subscription Based Sync

Update the `PostController` class to manage subscriptions for new posts and new comments on followed posts. Add functions for following and unfollowing individual posts.

When a user follows a `Post`, he or she will receive a push notification and automatic sync for new `Comment` records added to the followed `Post`.

#### Subscribe to New Posts

Create and save a subscription for all new `Post` records.

1. Add a function `subscribeToNewPosts` that takes an optional completion closure with `success` `Bool` and `error` `NSError?` parameters.
* note: Use an identifier that describes that this subscription is for all posts.
2. Implement the function by using the `CloudKitManager` to subscribe to newly created `Post` records. Run the completion closure, passing a successful result if the subscription is successfully saved.
3. Call the `subscribeToNewPosts` in the initializer for the `PostController` so that each user is subscribed to new `Post` records saved to CloudKit.

#### Subscribe to New Comments

Create and save a subscription for all new `Comment` records that point to a given `Post`

1. Add a function `addSubscriptionTo(commentsForPost post: ...)` that takes a `Post` parameter, an optional `alertBody` `String` parameter, and an optional completion closure with `success` `Bool` and `error` `Error` parameters.
2. Implement the function by using the `CloudKitManager` to subscribe to newly created `Comment` records that point to the `post` parameter. Run the completion closure, passing a successful result if the subscription is successfully saved.
* note: You will need to be able to identify this subscription later if you choose to delete it. Use a unique identifier on the `Post` as the identifier for the subscription so you can manage the matching subscription as needed.
* note: You will need an NSPredicate that checks if the `Comment`'s `post` is equal to the `post` parameter's `CKRecordID`

#### Manage Post Comment Subscriptions

The Post Detail scene allows users to follow and unfollow new `Comment`s on a given `Post`. Add a function for removing a subscription, and another function that will toggle a subscription for a given `Post`.

1. Add a function `removeSubscriptionTo(commentsForPost post: ...)` that takes a `Post` parameter and an optional completion closure with `success` and `error` parameters.
2. Implement the function by using the `CloudKitManager` to unsubscribe to the subscription for that `Post`.
* note: Use the unique identifier you used to save the subscription above. Most likely this will be your unique `recordName` for the `Post`.
3. Add a function `checkSubscriptionToPostComments` that takes a `Post` parameter and an optional completion closure with a `subscribed` `Bool` parameter.
4. Implement the function by using the `CloudKitManager` to fetch a subscription with the `post.recordName` as an identifier. If the subscription is not nil, the user is subscribed. If the subscription is nil, the user is not subscribed. Run the completion closure with the appropriate parameters.
5. Add a function `toggleSubscriptionTo(commentsForPost post: ...)` that takes a `Post` parameter and an optional completion closure with `success`, `isSubscribed`, and `error` parameters.
6. Implement the function by using the `CloudKitManager` to fetch subscriptions, check for a subscription that matches the `Post`, removes it if it exists, or adds it if it does not exist. Run the optional completion closure with the appropriate parameters.

### Update User Interface

Update the Post Detail scene's `Follow Post` button to display the correct text based on the current user's subscription. Update the outlet to toggle subscriptions for new comments on a `Post`.

1. Update the `updateViews` function to call the `checkSubscriptionTo(commentsForPost: ...)` on the `PostController` and set appropriate text for the button based on the response.
2. Implement the `Follow Post` button's IBAction to call the `toggleSubscriptionTo(commentsForPost: ...)` function on the `PostController` and update the `Follow Post` button's text based on the new subscription state.

### Add Permissions

Update the Info.plist to declare backgrounding support for responding to remote notifications. Request the user's permission to display remote notifications.

1. Go to the Project File. In the "capabilities" tab, turn on Push Notifications and Background Modes. Under Background Modes, check Remote Notifications.

2. Request the user's permission to display notifications in the `AppDelegate` `didFinishLaunchingWithOptions` function.
* note: Use the `requestAuthorization` function that is a part of `UNUserNotificationCenter`.

### Handle Received Push Notifications

At this point the application will save subscriptions to the CloudKit database, and when new `Post` or `Comment` records are created that match those subscriptions, the CloudKit database will deliver a push notification to the application with the record data.

Handle the push notification by serializing the data into a `Post` or `Comment` object. If the user is actively using the application, the user interface will be updated in response to notifications posted by the `PostController`.
s
1. Add the `didReceiveRemoteNotification` delegate function to the `AppDelegate`.
2. Implement the function by telling the `PostController` to call the `fetchPosts` function, which will fetch all new `Post`s and all new `Comment`s. Run the completion handler by passing in the `UIBackgroundFetchResult.NewData` response.
