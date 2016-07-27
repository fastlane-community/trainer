# xcode_log_parser

This is an alternative approach to generate JUnit files for your CI (e.g. Jenkins) without parsing the `xcodebuild` output, but the resulting Xcode `plist` files. 

## Installation

Add this to your `Gemfile` 
```
gem xcode_log_parser
```
and run
```
bundle install
```

Alternatively you can install the gem system-wide using `sudo gem install xcode_log_parser`.

## Usage

If you use `fastlane`, check out the official [fastlane plugin](https://github.com/KrauseFx/xcode_log_parser/tree/master/fastlane-plugin-xcode_log_parser#readme) on how to use `xcode_log_parser` in `fastlane`.

#### Run tests

```
cd [project]
scan --derived_data_path "output"
```

#### Convert the plist files to junit

```
xcode_log_parser
```

You can also pass a custom directory containing the plist files

```
xcode_log_parser --path ./something
```

For more information run

```
xcode_log_parser --help
````
