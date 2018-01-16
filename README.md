# Fun Facts! Splashscreens for RetroPie

A tool for RetroPie to generate splashscreens with random video game related fun facts.

**WARNING: Splashscreens are only available on the Raspberry Pi.**

## Installation

```
cd /home/pi/
git clone https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens.git
cd RetroPie-Fun-Facts-Splashscreens/
sudo chmod +x fun-facts-splashscreens.sh
```

You can also install **Fun Facts! Splashscreens** as a scriptmodule via the [RetroPie-Extra](https://github.com/zerojay/RetroPie-Extra) repository. Check the [supplementary](https://github.com/zerojay/RetroPie-Extra/#supplementary) section.

## Usage

```
sudo ./fun-facts-splashscreens.sh [OPTIONS]
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: sudo ./fun-facts-splashscreens.sh [OPTIONS]

Use '--help' to see all the options.
```

## Options

* `--help`: Print the help message and exit.
* `--splash-path [OPTIONS]`: Set which splashscreen to use.
* `--text-color [OPTIONS]`: Set which text color to use.
* `--create-fun-fact`: Create a new Fun Facts! splashscreen.
* `--apply-splash`: Apply Fun Facts! splashscreen.
* `--enable-boot`: Enable script to be launch at boot.
* `--disable-boot`: Disable script to be launch at boot.
* `--gui`: Start GUI.
* `--update`: Update script.
* `--version`: Show script version.

If `--splash-path` or `--text-color` are not set, the script takes the splashscreen and the text color defaults, `retropie-default.png` and `white`, respectively.

## Examples

### `--help`

Print the help message and exit.

#### Example

```
sudo ./fun-facts-splashscreens.sh --help
```

### `--splash-path [OPTIONS]`

Set which splashscreen to use.

#### Options

* `path/to/splashscreen`: Path to the splashscreen to be used.

#### Example

```
sudo ./fun-facts-splashscreens.sh --splash-path /home/pi/Downloads/retropie-2014.png
```

### `--text-color [OPTIONS]`

Set which text color to use.

#### Options

* `color`: Text color to be used.

#### Example

```
sudo ./fun-facts-splashscreens.sh --text-color black
```

### `--create-fun-fact`

Create a new Fun Facts! splashscreen.

The resulting splashscreen will be in `/home/pi/RetroPie/splashscreens/`.

#### Example

```
sudo ./fun-facts-splashscreens.sh --create-fun-fact
```

### `--apply-splash`

Apply Fun Facts! splashscreen.

This command must be run in order to use the **Fun Facts!** splashscreen.

#### Example

```
sudo ./fun-facts-splashscreens.sh --apply-splash
```

### `--enable-boot`

Enable script to be launch at boot.

**Backing up `/etc/rc.local` is most recommended before using this option. It could erase important stuff. Use it at your own risk.**

#### Example

```
sudo ./fun-facts-splashscreens.sh --enable-boot
```

### `--disable-boot`

Disable script to be launch at boot.

**Backing up `/etc/rc.local` is most recommended before using this option. It could erase important stuff. Use it at your own risk.**

#### Example

```
sudo ./fun-facts-splashscreens.sh --disable-boot
```

### `--gui`

Start GUI.

It lets you perform all the previous functions, but in a more friendly manner.

#### Example

```
sudo ./fun-facts-splashscreens.sh --gui
```

##### Set splashscreen path (`--splash-path`)
![Fun Facts Splashscreens GUI - 01](gui-examples/fun-facts-splashscreens-gui-01.jpg)
##### Enter path to splashscreen
![Fun Facts Splashscreens GUI - 02](gui-examples/fun-facts-splashscreens-gui-02.jpg)
##### Set text color (`--text-color`)
![Fun Facts Splashscreens GUI - 03](gui-examples/fun-facts-splashscreens-gui-03.jpg)
##### Choose a color
![Fun Facts Splashscreens GUI - 04](gui-examples/fun-facts-splashscreens-gui-04.jpg)
##### Create a new Fun Facts! splashscreen (`--create-fun-fact`)
![Fun Facts Splashscreens GUI - 05](gui-examples/fun-facts-splashscreens-gui-05.jpg)
##### Apply Fun Facts! splashscreen (`--apply-splash`)
![Fun Facts Splashscreens GUI - 06](gui-examples/fun-facts-splashscreens-gui-06.jpg)
##### Enable at boot (`--enable-boot`)
![Fun Facts Splashscreens GUI - 07](gui-examples/fun-facts-splashscreens-gui-07.jpg)
##### Disable at boot (`--disable-boot`)
![Fun Facts Splashscreens GUI - 08](gui-examples/fun-facts-splashscreens-gui-08.jpg)
##### Update script (`--update`)
![Fun Facts Splashscreens GUI - 09](gui-examples/fun-facts-splashscreens-gui-09.jpg)

### `--update`

Update script.

#### Example

```
sudo ./fun-facts-splashscreens.sh --update
```

If you're using **Fun Facts! Splashscreens** via RetroPie-Setup (if you installed it as a scriptmodule via the [RetroPie-Extra](https://github.com/zerojay/RetroPie-Extra) repository), this function won't work. The scriptmodules have their own update function.

If that's the case, go to:

* Manage packages
* Manage experimental packages
* fun-facts-splashscreens
* Update from source

### `--version`

Show script version.

#### Example

```
sudo ./fun-facts-splashscreens.sh --version
```

## Config file

When setting the splashscreen path using `--splash-path` or setting the text color using `--text-color`, whether it's done via the command line or the GUI, the generated values are stored in `fun-facts-splashscreens-settings.cfg`.

```
# Settings for Fun Facts!

# Splashscreen path
#
# Must be an absolute path.
# (e.g /home/pi/my-awesome-splashscreen.png)

splashscreen_path = ""

# Text color
#
# Short list of available colors:
#
# black, white, gray, gray10, gray25, gray50, gray75, gray90,
# pink, red, orange, yellow, green, silver, blue, cyan, purple, brown.
#
# TIP: run the 'convert -list color' command to get a full list.

text_color = ""
```

You can edit this file directly instead of using `--splash-path` or `--text-color`.

## Add a new Fun Fact!

* Open `fun-facts.txt`.
* Add a new **Fun Fact!** (see [style guide](#style-guide)).

### Style guide

* Each **Fun Fact!** must be in one line.
* All video game names must be enclosed in double quotes (e.g. "Sonic the Hedgehog").
* Check the names using the [TheGamesDB](http://thegamesdb.net/) or any other reliable source.
* **Fun Facts!** aren't funnier even if they're written with exclamations marks. Don't use them.
* Tacky **Fun Facts!** aren't funnier either.
* Stick to **Fun Facts!** about video games that can be played with RetroPie (see [supported systems](https://github.com/retropie/retropie-setup/wiki/Supported-Systems)).
* Try not to make **Fun Facts!** too long.

If you have an awesome **Fun Fact!** that you'd like to share, you can create a [new issue]((/CONTRIBUTING.md)) with your awesome **Fun Fact!** and I'll gladly add it to the repository for everyone to enjoy! 😃🎉

Also (and preferably), if you know how, you can create a [pull request](/CONTRIBUTING.md) 😉

## Changelog

See [CHANGELOG](/CHANGELOG.md).

## Contributing

See [CONTRIBUTING](/CONTRIBUTING.md).

## Authors

Me 😛 [@hiulit](https://github.com/hiulit).

## Credits

Thanks to:

* [Parviglumis](https://retropie.org.uk/forum/user/parviglumis) - For the idea of creating the [Fun Facts! Splashscreens](https://retropie.org.uk/forum/topic/13630).
* [meleu](https://github.com/meleu/) - For all his help and wisdom with the code and for all the PRs! :D
* [zerojay](https://github.com/zerojay/) - For adding **Fun Facts! Splashscreens** to the [RetroPie-Extra](https://github.com/zerojay/RetroPie-Extra) repository.
* [Thunderforge](https://github.com/Thunderforge) - For adding more [**Fun Facts!**](https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens/pull/13).
* All the people at the [RetroPie Forum](https://retropie.org.uk/forum/).

## License

[MIT License](/LICENSE).
