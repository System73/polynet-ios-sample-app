# System73® PolyNet sample application for iOS and tvOS

This is the integration sample application to integrate the PolyNet SDK for Apple platforms.

This example contains four projects, one for each platform and language. There are two iOS sample projects: one in **Swift** (PolyNetSampleSwift) and another in **Objective-C** (PolyNetSampleObjectiveC). Also, it contains two tvOS sample projects: one in **Swift** (PolyNetSample-tvOS) and another in **Objective-C** (PolyNetSample-tvOS-ObjectiveC).

## Running the sample

### Select the sample project to build

Select and enter the directory of the project you want to run. For example, PolyNetSampleSwift.

```shell
cd PolyNetSampleSwift
```

Then, select one of the following methods.

### Using Carthage

Navigate to a specific project (PolyNetSampleSwift, PolyNetSampleObjectiveC, etc.). Update the Carthage dependencies for the specific Apple platform (ios/tvos).

```shell
carthage update --platform ios --use-xcframeworks
```

After updating the Carthage dependencies, follow these steps (PolyNetSampleSwift project as a example):

1. Open the Xcode project (.xcodeproj) and navigate to the Frameworks folder.
2. Right-click the Frameworks folder and select "Add files to PolyNetSampleSwift."
3. Ensure that "Copy items if needed," "Create groups," and "Add to targets PolyNetSampleSwift" are selected.
4. Choose the XCFrameworks (PolyNetSDK, Starscream, and SwiftProtobuf) from the PolyNetSampleSwift/Carthage/Build folder.
5. Go to the "General" tab of your project settings and ensure that the added frameworks are set to "Embed & Sign."

### Using CocoaPods

Install or Update the dependencies.

```shell
pod update
```

*Beware to open the workspace (.xcworkspace) and not the project (.xcodeproj) itself to work with CocoaPods.*

Open the .xcworkspace file of your Xcode project and ensure that only Pods_PolyNetSampleSwift.framework is present in the Frameworks, Libraries, and Embedded Content sections.

After that, run the project from Xcode.

## Support

Please visit [system73.com/docs](https://www.system73.com/docs/) for more information or [contact us](mailto:support@system73.com).

[Carthage documentation](https://github.com/Carthage/Carthage)

[CocoaPods documentation](https://cocoapods.org/)
