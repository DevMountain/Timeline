# Timeline

### Level 3

Timeline is a simple photo sharing service. Students will bring in many concepts that they have learned, and add complex data modeling, Image Picker, Collection Views, NSURLSession, Firebase, and protocol-oriented programming to make a Capstone Level project spanning many days and concepts.

Most concepts will be covered during class, others are introduced during the project. Not every instruction will outline each line of code to write, but lead the student to the solution. 

Students who complete this project independently are able to:

#### Part One - Project Planning, Model Objects, and Controllers

* follow a project planning framework to build a development plan
* follow a project planning framework to prioritize and manage project progress
* implement a layered tab bar based view hierarchy
* implement a related data model architecture
* use staged data to prototype features

#### Part Two - Search Controller, Container Views, Apple View Controllers

* implement search using the system search controller
* use the image picker controller and activity controller
* use container views to implement similar functionality in multiple view controllers

#### Part Three - Basic CloudKit: CloudKitManager, CloudKitManagedObject, Manual Sync, Cloud Image Search

* check CloudKit availability
* save data to CloudKit
* fetch data from CloudKit
* query data from CloudKit
* sync pulled CloudKit data to a local Core Data persistent store

#### Part Four - Intermediate CloudKit: Subscriptions, Push Notifications, Automatic Sync, User Search

* use Discoverability to find other users
* use subscriptions to generate push notifications
* use push notifications to run a push based sync engine

## Part One - Project Planning, Model Objects, and Controllers

* follow a project planning framework to build a development plan
* follow a project planning framework to prioritize and manage project progress
* implement a layered tab bar based view hierarchy
* implement a related data model architecture
* use staged data to prototype features

Follow the development plan included with the project to build out the basic view hierarchy, basic implementation of local model objects, model object controllers, and helper classes. Build staged data to lay a strong foundation for the rest of the app.

### View Hierarchy

Implement a layered tab bar based view hierarchy. The app will have a Timeline tab and a Search tab. Each tab will display a list of `Post` objects and segue to a `Post` detail view.

1. Add a `UITabBarController` container view controller as the root view controller
2. Add a `UITableViewController` Timeline scene, embed it in a `UINavigationController`, add a + button as the right bar button, and add it to the `UITabBarController` via the `viewControllers` relationship segue. Update the `UITabBarItem` on the `UINavigationController` to describe the scene
    * note: The + button will be used to add photos
3. Add a `PostListTableViewController` subclass of `UITableViewController` and assign it to the Timeline scene
4. Add a `UITableViewController` Post Detail scene, add a segue to it from the Timeline scene
5. Add a `PostDetailTableViewController` subclass of `UITableViewController` and assign it to the Post Detail scene
6. Add a `UITableViewController` Add Post scene, embed it into a `UINavigationController`, and add a modal presentation segue to it from the + button on the Timeline scene
    * note: Because this scene will use a modal presentation, it will not inherit the `UINavigationBar` from the Timeline scene
6. Add a `UITableViewController` Search scene, embed it in a `UINavigationController`, and add it to the `UITabBarController` via the `viewControllers` relationship segue.
7. Add a `UITableViewcontroller` Search Results scene. It does not need a relationship to any other view controller.
    * note: You will implement this scene in Part 2 when setting up the `UISearchController` on the Search scene
8. Add a `UITableViewController` User Setup scene, embed it into a `UINavigationController`, and add a modal presentation segue to it from the `UITabBarController` scene. Assign an identifier.
    * note: This segue can be called manually, and this scene will be used when a new user has not been set up with a 'Display Name' or 'Profile Image'

### Implement Model

Timeline will use a Core Data local persistent storage with a CloudKit based sync engine. To begin, add Core Data to the project by creating a Core Data Model xcdatamodel file, and adding the `Stack` file that will be used to access Core Data. Then use the Core Data Model file to create your local Core Data model objects.

#### Post

Create a `Post` model object that will hold image data and a timestamp. Most often, Core Data is backed by a SQLite persistent store. SQLite databases are not built for managing large data blobs like photos. Use the 'Allows external storage' option to have Core Data manage storing the data to disk and including a reference to that data on disk in the actual SQLite data store.

1. Add a new `Post` Core Data entity to your managed object model. Add a `timestamp` Date attribute and a `photoData` Binary Data attribute. 
2. Select the `photoData` attribute and choose the 'Allows External Storage' option in the Attribute Inspector panel.
3. Create the `NSManagedObject` subclass files.
4. Add a convenience initializer that accepts a `photo` parameter as `NSData`, a `caption` parameter as a `String`, and a timestamp parameter as an `NSDate`.
5. Implement the convenience initializer, calling the `init(entity: insertIntoManagedObjectContext:)` function that normally is called by the `NSEntityDescription.entityForName(name:, inManagedObjectContext:) function.

Do not do anything with the `caption` parameter yet. Once you have implemented the `Comment` class, you will implement the `caption` parameter by adding it as the first `Comment` on the `Post` from the current user.

#### Comment

Create a `Comment` model object that will hold user-submitted text comments for a specific `Post`. 

1. Add a new `Comment` Core Data entity to your managed object model. Add a `timestamp` Date attribute and a `text` String attribute.
2. Add a relationship that supports adding multiple `Comment` object relationships to a single `Post` object, set the inverse relationship on the `Post` object.
3. Create the `NSManagedObject` subclass files.
4. Add a convenience initializer that accepts a `Post` parameter, a text parameter, and a timestamp parameter as an `NSDate`.
    * note: Include the `Post` parameter because a `Comment` cannot exist without a parent `Post`. This is a common pattern for doing [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection). 
5. Implement the convenience initializer, calling the `init(entity: insertIntoManagedObjectContext:)` function that normally is called by the `NSEntityDescription.entityForName(name:, inManagedObjectContext:) function.
6. Return to the `Post` class and unwrap the optional `caption` parameter to initialize the first `Comment` object.

#### User

Create a `User` model struct that will hold information about the current user. This will _not_ be a Core Data object. We will not put the User object in Core Data because it will only represent the _current user_ of the app, and `NSUserDefaults` is better suited to store current user data. Core Data would be a better option if we were to store many users. 

The user object is a simple struct of a display name and a profile image.

1. Add a `User` struct with `displayName: String` and `profileImageURL: NSURL?` properties.
2. Add a `profileImage: UIImage?` computed property that serves the `profileImageData` as a `UIImage` if it exists.
3. Add a `dictionaryValue` computed property that returns the object as a `[String: AnyObject]` that can be stored to `NSUserDefaults`.
4. Add a a failable initializer that can be used to restore a `User` struct from `NSUserDefaults`.

_Note: Not final. Expect User and User Controller API to change._

### Model Object Controller

Add and implement the `PostController` class that will be used for CRUD operations. Implement a Fetched Results Controller that can be used to populate the Timeline Post List scene.

1. Add a new `PostController` class file.
2. Add a `sharedController` singleton property.
3. Overwrite the initializer to implement an `NSFetchedResultsController` that pulls `Post` objects ordered by the `timestamp` property in reverse chronological order (latest post on top).
4. Add a `saveContext` function that saves the `Stack`'s `managedObjectContext`.
5. Add a `createPost` function that takes an image parameter as a `UIImage`, and a caption as a `String`, calls the appropriate `Post` initializer, and then saves the context.
6. Add a `addCommentToPost` function that takes a text parameter as a `String`, and a `Post` parameter, calls the appropriate `Comment` initializer, and then saves the context.

### User Controller

Add a `UserController` class that will be used to fetch user details and update the current user's profile. You will add function signatures, but the implementation of this class will come in a future step.

1. Add a new `UserController` class file.
2. Add a `sharedController` singleton property.
3. Add an optional `currentUser` `User` property.
4. Add an initializer that checks `NSUserDefaults` for current user data. If there is saved user data, initialize a `User` and set the `currentUser` property. Otherwise set `currentUser` to nil.
5. Add an `updateCurrentUser` function that takes a `displayName` parameter as a `String`, and a `profileImage` parameter as a `UIImage`. 
6. Implement the function to save the `UIImage` to the Documents Directory as a JPEG representation, initialize a new `User` struct with the `displayName` and `NSURL` pointing to the image, set it to the `currentUser`,  and save and save the new data to `NSUserDefaults`.
    * note: Just like it is not recommended to save image blog data to the Core Data SQLite database, we store the profile image to the Documents directory and only store a URL reference to it in NSUserDefaults
    * note: Try to implement the image saving using just documentation. [Hacking with Swift](https://www.hackingwithswift.com/example-code/media/how-to-save-a-uiimage-to-a-file-using-uiimagepngrepresentation) has great sample code (though you will want to save the image as a JPG, not a PNG). Remember to save the URL to the `User` struct.

_Note: Not final. Expect User and User Controller API to change._

### Add Classes and Wire Up Views

1. Add a `UITableViewController` subclass for each scene and set the correct class values in Interface Builder
    * note: `PostListTableViewController`, `PostDetailTableViewController`, `AddPostTableViewController`, `SearchTableViewController`, `SearchResultTableViewController`, `UserSetupTableViewController`

#### Timeline Scene - Post List Table View Controller

Implement the Post List Table View Controller. You will use a similar cell to display posts in multiple scenes in your application. Create a custom `PostTableViewCell` that can be reused in different scenes.

1. Implement the scene in Interface Builder by creating a custom cell with an image view that fills the cell. 
2. Create a `PostTableViewCell` class, add and implement an `updateWithPost` to the `PostTableViewCell` to update the image view with the `Post`'s photo.
3. Choose a height that will be used for your image cells. To avoid worrying about resizing images or dynamic cell heights, you may want to use a consistent height for all of the image views in the app.
4. Implement the `UITableViewDataSource` functions using the `NSFetchedResultsController` that lives on the `PostController`.
    * note: The final app does not need to support any editing styles, but you may want to include support for editing while developing early stages of the app.
5. Implement the `NSFetchedResultsControllerDelegate` functions to begin and end table view updates.
6. Implement the `prepareForSegue` function to check the segue identifier, capture the detail view controller, index path, selected post, and assign the selected post to the detail view controller.
    * note: You may need to quickly add a `post` property to the `PostDetailTableViewController` or return to this step.

#### Post Detail Scene

Implement the Post Detail View Controller. This scene will be used for viewing post images and comments. Users will also have the option to add a comment, share the image, or follow the user that created the post.

Use the table view's header view to display the photo and a toolbar that allows the user to comment, share, or follow. Use the table view cells to display comments.

1. Add a vertical `UIStackView` to the Header of the table view. Add a `UIImageView` and a `UIToolbar` to the stack view. Add 'Comment', 'Share', and 'Follow' `UIBarButtonItem`s to the toolbar. Set up your constraints so that the image view is the height you chose previously for displaying images within your app.
2. Update the cell to support comments that span multiple lines without truncating them. Set the `UITableViewCell` to the subtitle style. Set the number of lines to zero. Implement dynamic heights by setting the `tableView.rowHeight` and `tableView.estimatedRowHeight` in the `viewDidLoad`.
3. Add an `updateWithPost` function that will update the scene with the details of the post. Implement the function by setting the `imageView.image` and reloading the table view if needed.
4. Implement the `UITableViewDataSource` functions to display the comments on the `Post`.
5. Add an IBAction for the 'Comment' button. Implement the IBAction by presenting a `UIAlertController` with a text field, a Cancel action, and an 'OK' action. Implement the 'OK' action to initialize a new `Comment` via the `PostController` and reload the table view to display it.
    * note: Do not create a new `Comment` if the user has not added text.
6. Add an IBAction for the 'Share' and 'Follow' buttons. You will implement these two actions in a future step in the project.

#### Add Post Scene

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
7. Add a 'Cancel' `UIBarButtonItem` as the left bar button item. Implement the IBAction to dismiss the view.

#### Account Setup Scene

Create a scene that will be used to set up a new user with a Display Name and a Profile Image. This scene will look and function similarly to the Add Post scene with three sections.

Section 1: Large button to select an image, and a `UIImageView` to display the selected image
Section 2: Display Name text field
Section 3: Submit Changes button

Until you implement the `UIImagePickerController`, you will use a staged static image to add new posts.

1. Assign the table view to use static cells. Adopt the 'Grouped' cell style. Add three sections.
2. Build the first section by creating a tall image selection/preview cell. Add a 'Select Image' `UIButton` that fills the cell. Add an empty `UIImageView` that also fills the cell. Make sure that the button is on top of the image view so it can properly recognize tap events.
3. Build the second section by adding a `UITextField` that fills the cell. Assign placeholder text so the user recognizes what the text field is for.
4. Build the third section by adding a 'Submit Changes' `UIButton` that fills the cell. 
5. Add an IBAction to the 'Select Image' `UIButton` that assigns a static image to the image view (add a sample image to the Assets.xcassets that you can use for prototyping this feature), and removes the title text from the button.
    * note: It is important to remove the title text so that the user no longer sees that a button is there, but do not remove the entire button, that way the user can tap again to select a different image.
6. Add an IBAction to the 'Submit Changes' `UIButton` that checks for an `image` and `displayName`. If there is an `image` and a `displayName`, use the `UserController` to update the current user. If either the image or a caption is missing, present an alert directing the user to check their information and try again.
7. Add a 'Dismiss' `UIBarButtonItem` as the left bar button item. Implement the IBAction to dismiss the view.

#### A Note on Code Repetition

Consider the similarities between the 'Add Post' scene and the 'Account Setup' scene. The amount of repetition should give you pause. `Don't repeat yourself` (DRY) is a shared value among skilled software developers.

Avoiding repetition is an important way to become a better developer and maintain sanity when building larger applciations.

Imagine a scenario where you have three classes with similar functionality. Each time you fix a bug or add a feature to any of those classes, you must go and repeat that in all three places. This commonly leads to differences, which leads to bugs.

You will refactor the most similar part of these two classes (selecting and assigning an image) into one child view controller in Part 2. 

#### Account Setup Scene (contd.)

The 'Account Setup Scene' should be presented to the user immediately if the user has not added a profile image or a display name to their account.

Add functionality to the Timeline Post List scene to check for the current user. If there is no `currentUser` on the `UserController`, present the Account Setup scene by manually performing the segue you created to the Account Setup view controller from the Tab Bar Controller.

### Polish Rough Edges

At this point you should be able view added post images in the Timeline Post List scene, add new `Post` objects from the Add Post Scene, add new `Comment` objects from the Post Detail Scene, and persist and use user profile information provided by the current user. 

Use the app and polish any rough edges. Check table view cell selection. Check text fields. Check proper view hierarchy and navigation models.

### Black Diamonds

* Review the README instructions and solution code for clarity and functionality, submit a GitHub pull request with suggested changes.
* Provide feedback on the expectations for Part One to a mentor or instructor.

## Part Two - Search Controller, Container Views, Apple View Controllers

* implement search using the system search controller
* use the image picker controller and activity controller
* use container views to implement similar functionality in multiple view controllers

Add and implement search functionality to the search view. Implement the Image Picker Controller on the Account Setup scene and Add Post scene. Decrease the amount of repeated code by refactoring the similar functionality in the Account Setup and Add Post scenes into a child view controller that is used in both classes.

### Search Controller

#### Update the Model

Add a `SearchableRecord` protocol that requires a `matchesSearchTerm` function. Update the `Post` and `Comment` objects to conform to the protocol.

1. Add a new `SearchableRecord.swift` file.
2. Define a `SearchableRecord` protocol with a required `matchesSearchTerm` function that takes a `searchTerm` parameter as a `String` and returns a `Bool`.
    * note: Because this protocol will be used on `NSManagedObject`s, add the `@objc` keyword to the protocol.

Consider how each model object will match to a specific search term. What searchable text is there on a `Comment`? What searchable text is there on a `Post`?

3. Update the `Comment` class to conform to the `SearchableRecord` protocol. Return `true` if `text` contains the search term, otherwise return `false`.
4. Update the `Post` class to conform to the `SearchableRecord` protocol. Return `true` if any of the `Post` `comments` match, otherwise return `false`.

Use a Playground to test your `SearchableRecord` and `matchesSearchTerm` functionality and understand what you are implementing.

_Note: Not final. Expect the Search API and instructions to change._

#### Build Search Scene

Implement the Search Table View Controller and the Search Results Table View Controller. You will use the same cell that you built in the Timeline scene. Use the same  `PostTableViewCell` you built for the Timeline scene.

Search controllers typically have two views: a list view, and a search result view that displays the filtered results. You must create a 'search results view' that is overlayed on top of your list view when the search bar is actively editing, and then your main list view handles a `SearchResultsUpdating` protocol function that updates the results view.

Understanding Search Controllers requires you to understand that the main view controller can (and must) implement methods that handle what is being displayed on another view controller. The results controller must also implement a way to communicate back to the main list view controller to notify it of events. This two way relationship with communication happening in both directions.

##### Search Results Controller

1. Create a `SearchResultsTableViewController` subclass of `UITableViewController` and assign it to the scene in Interface Builder.
2. Add a `resultsArray` property that contains a list of `SearchableRecords`
3. Implement the `UITableViewDatasource` functions to display the search results.   
    * note: For now you will only display `Post` objects as a result of a search. Use the `PostTableViewCell` to do so.

##### Search Scene

1. Implement the scene in Interface Builder by updating the prototype cell with an image view that fills the cell. Use the Timeline scene's cell as the blueprint for constraints, views, height, etc.
2. Assign the cell to your `PostTableViewCell` class.
    * note: As of Xcode 7, you must set up the views for the cell for each separate table view in the Storyboard, but you can assign multiple views to the same class, and have outlets or actions triggered from multiple instances.
3. Add a `posts` array as a property on the `SearchTableViewController`.
    * note: You will populate this array with remote search results. 
4. Update the `viewDidLoad` function to set the `posts` array to a copy of the `fetchedObjects` from the Fetched Results Controller.
    * note: To build prototype search functionality for this scene, you will use the local posts as the initial datasource. 
5. Implement the `UITableViewDataSource` functions using the `posts` array.
6. Add a function `setUpSearchController` that captures the `resultsController` from the Storyboard, instantiates the `UISearchController`, sets the `searchResultsUpdater` to self, and adds the `searchController`'s `searchBar` as the table's header view.
7. Implement the `UISearchResultsUpdating` protocol `updateSearchResultsforSearchController` function. The function should capture the `resultsViewController` and the search text from the `searchController`'s `searchBar`, filter the local `posts` array for posts that match, assign the filtered results to the `resultsViewController`'s `resultsArray`, and reload the `resultsViewController`'s `tableView`.
    * note: Consider the communication that is happening here between two separate view controllers. Be sure that you understand this relationship.

##### Segue to Post Detail View

Remember that even though the tableviews are displaying similar cells and model objects, you are working with separate view controllers with separate cells and instances of table views. 

The segue from a `Post` should take the user to the Post Detail scene, regardless of whether that is from the Search Scene or the Search Results scene.

To do so, implement the `UITableViewDelegate` `didSelectRow` function on the Search Results scene to manually call the `toPostDetail` segue _from the Search scene_.

1. Implement a segue on the Search Scene to check for the segue identifier, capture the detail view controller, index path, selected post, and assign the selected post to the detail view controller.
    * note: Should be similar to the segue used on the Timeline scene
2. Adopt the `UITableViewDelegate` on the Search Results scene and add the `didSelectRowAtIndexPath` function. Implement the function by capturing the sending cell and telling the Search Result scene's `presentingViewController` to `performSegueWithIdentifier` and send the selected cell so that the Search scene can get the selected `Post`.
    * note: Every view controller class has an optional `presentingViewController` reference to the view controller that presented it. In this case, the presenting view controller of the Search Results scene is the Search scene. So this step will manually call the `performSegueWithIdentifier` on the Search scene.
3. Update the `prepareForSegue` function on the Search Scene to capture and segue to the Post Detail scene with the correct post. Try to do so without looking at the solution code.
    * note: You must check if the `tableView` can get an `indexPath` for the sender. If it can, that means that the cell was from the Search scene's `tableView`. If it can't, that means the cell is from the Search Result scene's `tableView` and that the user tapped a search result. If that is the case, capture the `Post` from the `resultsArray` on the `searchResultscontroller`.
    * note: You can access the `searchResultsController` by calling `(searchController.searchResultsController as? SearchResultsTableViewController)`

Try to work through the Search segue without looking at the solution code. Understanding this pattern will solidify your understanding of many object-oriented programming patterns.


### Image Picker Controller

#### Add Post Scene

Implement the Image Picker Controller in place of the prototype functionality you built previously.

1. Update the 'Select Image' IBAction to present a `UIImagePickerController`. Give the user the option to select from their Photo Library or from the device's camera if their device has one. 
2. Implement the `UIImagePickerControllerDelegate` function to capture the selected image and assign it to the image view.

#### Account Setup Scene

Implement the Image Picker Controller in place of the prototype functionality you built previously.

1. Update the 'Select Image' IBAction to present a `UIImagePickerController`. Give the user the option to select from their Photo Library or from the device's camera if their device has one. 
2. Implement the `UIImagePickerControllerDelegate` function to capture the selected image and assign it to the image view.


### Reduce Code Repetition

Refactor the photo selection functionality from the Account Setup and Add Post scenes into a child view controller. 

Child view controllers control views that are a subview of another view controller. It is a great way to encapsulate functionality into one class that can be reused in multiple places. This is a great tool for any time you want a similar view to be present in multiple places.

In this instance, you will put 'Select Photo' button, the image view, and the code that presents and handles the `UIImagePickerController` into a `PhotoSelectorViewController` class. You will also define a protocol for the `PhotoSelectorViewController` class to communicate with it's parent view controller.

#### Container View and Embed Segues

Use a container view to embed a child view controller into the Account Setup scene and Add Post scene.

>Container View defines a region within a view controller's view subgraph that can include a child view controller. Create an embed segue from the container view to the child view controller in the storyboard.

1. Open `Main.storyboard` to your Account Setup scene.
2. Add a new section to the static table view to build the Container View to embed the child view controller.
3. Search for Container View in the Object Library and add it to the newly created table view cell.
    * note: The Container View object will come with a view controller scene. You can use the included scene, or replace it with another scene. For now, use the included scene.
4. Set up contraints so that the Container View fills the entire cell.
5. Move or copy the Image View and 'Select Photo' button to the container view controller.
6. Create a new `PhotoSelectViewController` file as a subclass of `UIViewController` and assign the class to the scene in Interface Builder.
7. Create the necessary IBOutlets and IBActions, and migrate your Photo Picker code from the Account Setup view controller class. Delete the old code from the Account Setup view controller class.
8. Repeat the above steps for the Add Post scene. Instead of keeping the included child view controller from the Container View object, delete it, and add an 'Embed' segue from the container view to the scene you set up for the Account Setup scene.

You now have two views that reference the same scene as a child view controller. This scene and accompanying class can now be used in both places, eliminating the need for code duplication.

#### Child View Controller Delegate

Your child view controller needs a way to communicate events to it's parent view controller. This is most commonly done through delegation. Define a child view controller delegate, adopt it in the parent view controller, and set up the relationship via the embed segue.

1. Define a new `PhotoSelectViewControllerDelegate` protocol in the `PhotoSelectViewController` file with a required `photoSelectViewControllerSelectedImage` function that takes a `UIImage` parameter to pass the image that was selected.
    * note: This function will tell the assigned delegate (the parent view controller, in this example) what image the user selected.
2. Add a weak optional delegate property.
3. Call the delegate function in the `didFinishPickingMediaWithInfo` function, passing the selected media to the delegate.
4. Adopt the `PhotoSelectViewControllerDelegate` protocol in the Account Setup class file, implement the `photoSelectViewControllerSelectedImage` function to capture a reference to the selected image.
    * note: In the Account Setup scene, you will use that captured reference to update the user.
5. Adopt the `PhotoSelectViewControllerDelegate` protocol in the Add Post class file, implement the `photoSelectViewControllerSelectedImage` function to capture a reference to the selected image.
    * note: In the Add Post scene, you will use that captured reference to create a new post.

Note the use of the delegate pattern. You have encapsulated the Photo Selection workflow in one class, but by implementing the delegate pattern,  each parent view controller can implement it's own response to when a photo was selected. 

You have declared a protocol, adopted the protocol, but you now must assign the delegate property on the instance of the child view controller so that the `PhotoSelectViewController` can communicate with it's parent view controller. This is done by using the embed segue, which is called when the Container View is initialized from the Storyboard, which occurs when the view loads.

1. Assign segue identifiers to the embed segues in the Storyboard file
2. Update the `prepareForSegue` function in the Account Setup scene to check for the segue identifier, capture the `destinationViewController` as a `PhotoSelectViewController`, and assign `self` as the child view controller's delegate.

### Black Diamonds:

* Some apps will save photos taken or processed in their app in a custom Album in the user's Camera Roll. Add this feature.
* Review the README instructions and solution code for clarity and functionality, submit a GitHub pull request with suggested changes.
* Provide feedback on the expectations for Part One to a mentor or instructor.