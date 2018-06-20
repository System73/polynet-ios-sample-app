# System73® PolyNet sample application for iOS and tvOS

This is the integration sample application for the PolyNet iOS SDK and PolyNet tvOS SDK.

These sample applications are compatible with PolyNetSDK version 4. If you need a sample application for version 3 or 2, you need to make a checkout for the tags *PolyNetSDK-version-3* or *PolyNetSDK-version-2* (git checkout [tag]).

In order to run those applications you need a zip containing the PolyNetSDK and its dependencies for the specific platform (iOS, tvOS).

## iOS

There are two iOS sample projects, one in **Swift** (PolyNetSampleSwift) and another in **Objective-C** (PolyNetSampleObjectiveC).

In order to build and run any of the iOS sample projects you have to put a copy of the PolyNet iOS SDK (*PolyNetSDK.framework*) and its dependencies (*WebRTC.framework*, *Starscream.framework*, *SwiftProtobuf.framework* and the folder *zlib*) in the corresponding root project directory (PolyNetSampleSwift or PolyNetSampleObjectiveC directory).

The Sample application expects to find the iOS SDK and its dependencies in its root directory in order to successfully link and build the project.

## tvOS

There is a tvOS sample project in **Swift** (PolyNetSample-tvOS).

In order to build and run the tvOS sample project you have to put a copy of the PolyNet tvOS SDK (*PolyNetSDK.framework*) and its dependencies (*WebRTC.framework*, *Starscream.framework*, *SwiftProtobuf.framework* and the folder *zlib*) in the corresponding root project directory (PolyNetSample-tvOS directory).

The Sample application expects to find the tvOS SDK and its dependencies in its root directory in order to successfully link and build the project.

## Support

Please visit [system73.com/docs](https://www.system73.com/docs/) for more information or [contact us](mailto:support@system73.com).
