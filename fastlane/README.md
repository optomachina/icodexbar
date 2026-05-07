fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios generate

```sh
[bundle exec] fastlane ios generate
```

Generate Xcode project from project.yml

### ios lint

```sh
[bundle exec] fastlane ios lint
```

Run SwiftLint

### ios format_check

```sh
[bundle exec] fastlane ios format_check
```

Run SwiftFormat (check mode)

### ios format

```sh
[bundle exec] fastlane ios format
```

Run SwiftFormat (apply changes)

### ios check

```sh
[bundle exec] fastlane ios check
```

Run all code quality checks

### ios build_debug

```sh
[bundle exec] fastlane ios build_debug
```

Build Debug configuration (CI sanity build, no archive, no signing)

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build Release configuration (CI sanity build, no archive, no signing)

### ios test

```sh
[bundle exec] fastlane ios test
```

Run unit tests (macOS companion target)

### ios ui_test

```sh
[bundle exec] fastlane ios ui_test
```

Run UI tests

### ios ci

```sh
[bundle exec] fastlane ios ci
```

Build and test

### ios archive_release

```sh
[bundle exec] fastlane ios archive_release
```

Archive Release for distribution

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit to App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
