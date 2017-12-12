# Changelog

## Unreleased

* Up to date.

## v1.0.0 (December 11th 2017)

#### Added

* Merged [#4](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/pull/4) from [@meleu](https://github.com/meleu).
    * Added `--splash` argument.
    * Added `--text-color` argument.
* Added `--gui` argument. All the functions can be performed in a more friendly manner.
* Created `fun-facts-settings.cfg` config file.
* Added a bunch of new **Fun Facts!**.

### Changes

* Default splashscreen is now `default-splashscreen.png`.
* Resulting Fun Facts! splashscreen is now `fun-facts-splashscreen.png`.
* Use of `--splash` to set splashscreen path.
* Use of `--text-color` to set text color.
* `fun-facts-settings.cfg` can be edited directly instead of using `--splash` or `--text-color` to store the splashscreen path and the text color values.

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
