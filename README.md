# trainer

This is an alternative approach to generate JUnit files for your CI (e.g. Jenkins) without parsing the `xcodebuild` output, but the resulting Xcode `plist` files. 

## Installation

Add this to your `Gemfile` 
```
gem trainer
```
and run
```
bundle install
```

Alternatively you can install the gem system-wide using `sudo gem install trainer`.

## Usage

If you use `fastlane`, check out the official [fastlane plugin](https://github.com/KrauseFx/trainer/tree/master/fastlane-plugin-trainer#readme) on how to use `trainer` in `fastlane`.

#### Run tests

```
cd [project]
scan --derived_data_path "output"
```

#### Convert the plist files to junit

```
trainer
```

You can also pass a custom directory containing the plist files

```
trainer --path ./something
```

For more information run

```
trainer --help
````

### Thanks

After the [lobbying of @steipete](https://twitter.com/steipete/status/753662170848690176) and the comment

> How does Xcode Server parse the results?

I started investigating alternative approaches on how to parse test results.