# Changelog

## v0.2.0 (November 15th 2017)

### Added

* Options:
    * `--help`: Print the help message and exit.
    * `--enable-boot`: Enable script to be launch at boot.
    * `--disable-boot`: Disable script to be launch at boot.
    * `--create-fun-fact`: Create Fun Fact Splashscreen.

### Changed

* If no option is passed, user gets prompted with a usage example.
* To create the Fun Fact Splashscreen, the user must pass `--create-fun-fact` option to the script.

### Deprecated

* ~~Now the scripts adds the line in `/etc/rc.local` to launch itself at boot automatically.~~ The user must enable this function (launch script at boot) by passing `--enable-boot` option to the script instead of adding it automatically.

## v0.1.0 (November 14th 2017)

* The script creates a splashscreen with random fun facts.
* Now the scripts adds the line in `/etc/rc.local` to launch itself at boot automatically.
