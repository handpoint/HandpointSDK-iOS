![HandpointSDK](https://github.com/handpoint/HandpointSDK-iOS/raw/master/logo.png)

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/HandpointSDK.svg)](https://img.shields.io/cocoapods/v/HandpointSDK.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/HandpointSDK.svg?style=flat)](https://cocoapods.org/pods/HandpointSDK)


- [Required Settings](#required-settings)
- [Installation](#installation)
    - [CocoaPods](#cocoapods)
    - [Carthage](#carthage)
    - [Manually](#manually)
- [Full SDK Documentation](#full-sdk-documentation)


## Required Settings

To be able to use HanbdpointSDK you need to setup some things first:

#### Setup external accessory protocols in your `Info.plist`

Add/modify the property "Supported external accessory protocols" and add *com.datecs.pinpad*

This is what it should look like in the "source code" view of your info.plist:

```plist
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.datecs.pinpad</string>
</array>
```

**Important**

The Handpoint bluetooth card readers are part of the Apple MFi program. In order to release apps supporting accessories that are part of the MFi Program, you have to apply at Apple. Please fill the [MFi form](http://hndpt.co/hp-mfi) and we will help you with this process.

#### Setup external accessory communication background mode

Enable support for external accessory communication from the Background modes section of the Capabilities tab in your Xcode project.

You can also enable this support by including the UIBackgroundModes key with the `external-accessory` value in your app’s Info.plist file:

```plist
<key>UIBackgroundModes</key>
<array>
    <string>external-accessory</string>
</array>
```

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

If you don't have a `Podfile` yet:

```bash
$ pod init
```

To integrate HandpointSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target 'your_target' do
    pod 'HandpointSDK', '~> 3.2.3'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](https://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate HandpointSDK into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "handpoint/HandpointSDK-iOS"
```

Run `carthage update` to build the framework and drag the built `HandpointSDK.framework` into your Xcode project.

### Manually

If you'd rather handle the dependency manually there are three approaches to include `HandpointSDK` in your project:

#### Prebuilt static library

Download the latest pre-built static library from [Handpoint's developer portal](https://www.handpoint.com/docs/device/iOS/) and refer to the documentation there for the installation steps.

#### Building the project yourself

Download the latest version from the master branch:

  ```bash
  $ git clone https://github.com/handpoint/HandpointSDK-iOS.git
  ```

Alternatively you can add it as a git [submodule](https://git-scm.com/docs/git-submodule):

  ```bash
  $ git submodule add https://github.com/handpoint/HandpointSDK-iOS.git
  ```

#### Framework

You'll find the dynamic framework project called `HandpointSDK.xcodeproj` at the root of the repo.

#### Static Library

You'll find the static library project called `headstart.xcodeproj` under the `Library` folder.

We **strongly** discourage you from building this project yourself.
 
This project contains several targets, you need to build the aggregated target `device-simulator Release`

This target produces a .zip file in the same directory as the `headstart.xcodeproj` file containing both the library and the simulator library.

## Full SDK Documentation

Full SDK documentation can be found at [Handpoint's developer portal](https://www.handpoint.com/docs/device/iOS/).
