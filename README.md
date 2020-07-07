#### Transformers assessment for Aequilibrium

Pierre Houston, jpmhouston@gmail.com

------

##### Instructions

1. Open Transformers.xcworkspace in Xcode 11.5 (might work fine in other versions, but I haven't checked)
2. set build destination to iOS Simulator as any iPhone or iPad device
3. Product > Run

Project uses the Kingfisher Cocoapod for image caching and while I usually omit the Pods directory from a source repo, I included it to reduce the steps needed to produce a build.

##### Of Note

- Universal: Navigation Controller behaviour on iPhone and well adapted to Master-Detail behaviour on iPad, looking good in all orientations
- Battle results are shown in progression round by round
- Unique feature: icon at left side of list cells used to select which Transformers from list will join battle and which will be "benched"
- Unit tests for model layer, networking utility, synchronization of authorization and list download
- Test feature can load and save Transformer data to local storage instead of server API
- Every view controller amenable to isolated instantiation
- Battle view controller amenable to UI Automation and can be driven by script-provided data in a simple text format (or manually: see startBattle in Views/ListViewController.swift and "Automated data creation" in Models/Fight.swift)

