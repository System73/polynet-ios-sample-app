# System73® PolyNet sample application for iOS and tvOS

This is the integration sample application for the PolyNet iOS SDK and PolyNet tvOS SDK.

This example contains four projects, one for each platform and language. There are two iOS sample projects one in **Swift** (PolyNetSampleSwift) and another in **Objective-C** (PolyNetSampleObjectiveC) also contents a tvOS sample project in **Swift** (PolyNetSample-tvOS) and another in **Objective-C** (PolyNetSample-tvOS-ObjectiveC).

Polynet can be integrated into the desired project manually method using the *Using provided Zips*, through Carthage o CocoaPods. (see [iOS PolyNet integration docs](https://system73.com/docs/ios/polyNetSDK/)).
You can to make a checkout for the tags defined below depending integration method.

## PolyNetSDK-version-4

This tag is the indicted to manual integration using the method *Using provided Zips*.

In order to build and run any sample projects you have to put a copy of the PolyNet SDK (*PolyNetSDK.framework*) and its dependencies (*Starscream.framework* and *SwiftProtobuf.framework*) in the corresponding root project directory (PolyNetSampleSwift or PolyNetSampleObjectiveC directories).

The Sample application expects to find the  SDK and its dependencies correspondiente a su platarforma (iOS or tvOS) in its root directory in order to successfully link and build the project.

## PolyNetSDK-version-4-carthage

This tag is the indicted to carthage integration and contains a Cartfile and xcconfig file defined in every project.

In order to build and run any sample projects you need to excute the bellow commands in the root directory:
`XCODE_XCCONFIG_FILE=$PWD/tmp.xcconfig`
`carthage update --platform iOS, tvOS`

Once carthage builds the dependencies, any proyect can be run successfully.
The tmp xcconfing file is temporally solution for exclude arm64  simulator arch.

## PolyNetSDK-version-4-cocoapods

This tag is the indicted to CocoaPods integration and contains a Podfile defined in every project.

In order to build and run any sample projects you need to excute the bellow command in the root directory:
`pod install`

Once CocoaPods install the dependencies, any proyect can be run successfully.

## Support

Please visit [system73.com/docs](https://www.system73.com/docs/) for more information or [contact us](mailto:support@system73.com).
