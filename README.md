# plist2junit

Because JUnit can actually be parsed

## Installation

```
git clone https://github.com/KrauseFx/xcode_log_parser
cd xcode_log_parser
bundle install
rake install
```

## Usage

### Run tests

```
cd [project]
xcodebuild -workspace [name].xcworkspace \
     -scheme "[scheme]" \
     -sdk iphonesimulator \
     -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.3' \
     -derivedDataPath './output'
```

### Convert the plist files to junit

```
xcode_log_parser
```
