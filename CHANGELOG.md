# Changelog

## Unreleased

### Fixed

* Fixed files permissions after updating the script.

### Added

* Added functionality to enable/disable script at boot in config file.
* Added functionality to download the config file if it doesn't exist.
* Added functionality to download the default RetroPie's splashscreen if it doesn't exist.

### Changed

* Updated **Fun Facts!**.
* Changed `default-splashscreen.png` for `retropie-default.png`.
* Changed `fun-facts-settings.cfg` for `fun-facts-splashscreens-settings.cfg`.
* Silenced some outputs.
* Removed `CODE_OF_CONDUCT.md`, `ISSUE_TEMAPLATE.md` and `PULL_REQUEST_TEMPLATE.md` as nobody, not even me, was using them :)

## v1.5.0 (January 15th 2018)

### Fixed

* Fixed issue in `create_fun_fact()` which was not getting proper values and therefore making the function not to work.
* Fixed issue in `Set splashscreen path` option which was setting the path incorrectly.

### Added

* Merged [#16](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/pull/16) - More **Fun Facts!** thanks to [Thunderforge](https://github.com/Thunderforge).
* Added documentation for `--version`.
* Added a [style guide](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens#style-guide) for adding new **Fun Facts!**.

### Changed

* Applied the [style guide](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens#style-guide) to **Fun Facts!**.
* Updated help for the scriptmodule.
* Cleaned up code and comments.
* Changed some outputs that were too much verbose.

## v1.4.1 (December 30th 2017)

### Fixed

* Don't check for updates when using script as scriptmodule.

## v1.4.0 (December 29th 2017)

### Added

* Check if there are updates to download [#12](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/issues/12).
* Split colors into **basic colors** and **full list of colors** [#9](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/issues/9).

## v1.3.0 (December 26th 2017)

### Added

* Merged [#13](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/pull/13) - More **Fun Facts!** thanks to [Thunderforge](https://github.com/Thunderforge).
* Added `--version` to check the version of the script.
* Added `check_version` and `get_last_commit` functions.
* Updated help info when using `--help`.

### Changed

* Removed `check_config` for `apply_splash` (not needed).

## v1.2.0 (December 21st 2017)

### Added

* Check to see if **Fun Facts!** splashscreen is already created before trying to apply it.

### Fixed

* Fixed **Version** and **Last commit**.
* Fixed `--update` function to show a message box when using the script as a scriptmodule.

## v1.1.0 (December 18th 2017)

### Added

* `--apply-splash` to use the generated **Fun Facts!** splashscreen.
* `--update` to check if the **Fun Facts!** script needs updates.

### Deprecated

* ~~`--splash`~~ is now `--splash-path`.

## v1.0.1 (December 13th 2017)

### Fixed

* Fixed a typo that was making `getDepends` not working in the scriptmodule.

## v1.0.0 (December 12th 2017)

### Added

* Merged [#4](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/pull/4) from [@meleu](https://github.com/meleu).
    * Added `--splash` argument.
    * Added `--text-color` argument.
* Added `--gui` argument. All the functions can be performed in a more friendly manner.
* Created `fun-facts-splashscreens-settings.cfg` config file.
* Added a bunch of new **Fun Facts!**.

### Changes

* Default splashscreen is now `default-splashscreen.png`.
* Resulting Fun Facts! splashscreen is now `fun-facts-splashscreen.png`.
* Use of `--splash` to set splashscreen path.
* Use of `--text-color` to set text color.
* `fun-facts-splashscreens-settings.cfg` can be edited directly instead of using `--splash` or `--text-color` to store the splashscreen path and the text color values.

### Deprecated

* Removed arguments for `--create-fun-fact` and `--enable-boot`. Added `--splash` to set the splashscreen path and `--text-color` to set the text color.
    * ~~Options for `--create-fun-fact`:~~
        * ~~`$1`: Path to the splashscreen to be used.~~
        * ~~`$2`: Text color.~~
    * ~~Options for `--enable-boot`:~~
        * ~~`$1`: Path to the splashscreen to be used.~~
        * ~~`$2`: Text color.~~

## v0.4.0 (November 18th 2017)

### Added

* Options for `--enable-boot`:
    * `$1`: Path to the splashscreen to be used.
    * `$2`: Text color.

Example: `sudo ./fun-facts-splashscreens.sh --enable-boot /home/pi/Downloads/retropie-2014.png black`

If no options are passed to `--create-fun-fact`, the script takes the splashscreen and the text color defaults, `splash4-3.png` and `white`, respectively.

## v0.3.0 (November 17th 2017)

### Added

* Options for `--create-fun-fact`:
    * `$1`: Path to the splashscreen to be used.
    * `$2`: Text color.

Example: `sudo ./fun-facts-splashscreens.sh --create-fun-fact /home/pi/Downloads/retropie-2014.png black`

If no options are passed to `--create-fun-fact`, the script takes the splashscreen and the text color defaults, `splash4-3.png` and `white`, respectively.

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
