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

Update the carthage dependencies for the specific Apple platform. 

```shell
carthage update --platform ios --use-xcframeworks
```

Go to the Frameworks folder inside the Xcode project (.xcodeproj) and remove the PolyNetSDK, Starscream, and SwiftProtobuf frameworks that are marked in red and are not being found by Xcode. After removing them, right-click inside the frameworks folder and select "Add files to 'project name'". Then choose the XCFrameworks (PolyNetSDK, Starscream and SwiftProtobuf) from the Carthage/Build folder. Once added, run the project from Xcode.

### Using CocoaPods

Install or Update the dependencies.

```shell
pod update
```

*Beware to open the workspace (.xcworkspace) and not the project (.xcodeproj) itself to work with CocoaPods.*

Go to the Frameworks folder inside the Xcode project workspace (.xcworkspace) and delete the PolyNetSDK, Starscream, and SwiftProtobuf frameworks. Only keep the Pods_PolyNetSampleSwift.framework. After that, run the project from Xcode.

## Support

Please visit [system73.com/docs](https://www.system73.com/docs/) for more information or [contact us](mailto:support@system73.com).

[Carthage documentation](https://github.com/Carthage/Carthage)

[CocoaPods documentation](https://cocoapods.org/)
