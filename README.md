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

Checkout the tag PolyNetSDK-version-5-carthage in the repository.

```shell
git checkout PolyNetSDK-version-5-carthage
```

Update the carthage dependencies for the specific Apple platform. For example, iOS for PolyNetSampleSwift.

```shell
carthage update --platform ios --use-xcframeworks
```

Run the project from Xcode.

### Using CocoaPods

Checkout the tag PolyNetSDK-version-5-cocoapods in the repository.

```shell
git checkout PolyNetSDK-version-5-cocoapods
```

Install the dependencies.

```shell
pod install
```

Run the created workspace from Xcode.

*Beware to open the workspace (.xcworkspace) and not the project (.xcodeproj) itself to work with CocoaPods.*

## Support

Please visit [system73.com/docs](https://www.system73.com/docs/) for more information or [contact us](mailto:support@system73.com).

[Carthage documentation](https://github.com/Carthage/Carthage)

[CocoaPods documentation](https://cocoapods.org/)