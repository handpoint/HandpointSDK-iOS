## How to release the HandpointSDK for iOS

### Registering with CocoaPods Trunk

Before publishing a new version of the SDK to the CocoaPods public repository, you must be registered with the CocoaPods Trunk service.

Follow these steps to register:

1. Open your terminal and run the following command:

```bash
$ pod trunk register your_email@handpoint.com "Your Name" --description="Work Laptop"
```

Replace `your_email@handpoint.com` with your actual email address.

Replace `Your Name` with your full name.

The `--description` flag is optional, but useful to identify the device you're registering from (e.g., "MacBook Pro" or "CI Server").

2. Check your inbox. You will receive a verification email from CocoaPods.

3. Click the link in the email to verify your registration.

4. Once verified, you can confirm your session is active by running:

```bash
$ pod trunk me
```
You should see your name, email, and a list of active sessions.

You only need to do this once per machine. After registering, you’ll be able to publish new versions using pod trunk push.

---

### Releasing a New Version of the HandpointSDK (iOS)

Follow these steps to release a new version of the SDK using CocoaPods:

> ⚠️ Make sure you are [registered with CocoaPods Trunk](#registering-with-cocoapods-trunk) before proceeding.

#### Finalize your code changes
Ensure all changes are committed and pushed to the main branch:

```bash
$ git add .
$ git commit -m "Release <version>"
$ git push origin main
```

Note: to update the version number in the `.podspec` file:

```ruby
s.version = "<new_version>"
```

#### Validate the .podspec file
Run the following command to validate that your `.podspec` is correctly configured:

```bash
$ pod spec lint HandpointSDK.podspec --verbose --allow-warnings
```

- Use `--allow-warnings` if your SDK emits any safe warnings.
- Make sure the validation passes before continuing.

#### Tag the new version in Git
Create an annotated git tag that matches the version number in the `.podspec`:

```bash
$ git tag -a <version> -m "<version> - Short changelog or description"
$ git push origin --tags
```
📌 The tag must match exactly the version defined in the `.podspec`.

#### Publish to CocoaPods Trunk
Once the tag is pushed and the `.podspec` is valid, publish the new version:

```bash
$ pod trunk push HandpointSDK.podspec --allow-warnings
```

If successful, the new version will be publicly available via CocoaPods.

#### Confirm the release
You can check that the new version is available by visiting:

👉 https://cocoapods.org/pods/HandpointSDK