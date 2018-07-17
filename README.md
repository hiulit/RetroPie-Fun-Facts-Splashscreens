# Fun Facts! Splashscreens for RetroPie

A tool for RetroPie to generate splashscreens with random video game related Fun Facts!.

## Installation

```bash
cd /home/pi/
git clone https://github.com/hiulit/RetroPie-Fun-Facts-Splashscreens.git
cd RetroPie-Fun-Facts-Splashscreens/
sudo chmod +x fun-facts-splashscreens.sh
```

You can also install **Fun Facts! Splashscreens** as a scriptmodule via the [RetroPie-Extra](https://github.com/zerojay/RetroPie-Extra) repository. Check the [supplementary](https://github.com/zerojay/RetroPie-Extra/#supplementary) section.

## Usage

```bash
sudo ./fun-facts-splashscreens.sh [OPTIONS]
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: sudo ./fun-facts-splashscreens.sh [OPTIONS]

Use '--help' to see all the options.
```

## Options

* `--help`: Print the help message.
* `--add-fun-fact [TEXT]`: Add new **Fun Facts!**.
* `--remove-fun-fact`: Remove **Fun Facts!**.
* `--create-fun-fact ([SYSTEM] [ROM])`: Create a new **Fun Facts! Splashscreen**.
* `--enable-boot-splashscreen`: Enable the script to create a boot splashscreen at startup.
* `--disable-boot-splashscreen`: Disable the script to create a boot splashscreen at startup.
* `--enable-launching-images`: Enable the script to create launching images using `runcommand-onend.sh`.
* `--disable-launching-images`: Disable the script to create launching images using `runcommand-onend.sh`.
* `--edit-config`: Edit the configuration file.
* `--reset-config`: Reset the configuration file.
* `--restore-defaults`: Restore the default files.
* `--gui`: Start the GUI.
* `--update`: Update the script.
* `--version`: Show the script version.

## Default configuration

* `splashscreen_path`: `./retropie-default.png`
* `text_color`: `white`
* `boot_script`: `false`
* `log`: `false`

See the [configuration file](#configuration-file).

## Examples

### `--help`

Print the help message.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --help
```

### `--add-fun-fact [OPTIONS]`

Add new **Fun Facts!**.

#### Options

* `text`: **Fun Fact!** text.

Wrap the text with double quotes `"`.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --add-fun-fact "I'm a new and amazing Fun Fact!"
```

### `--remove-fun-fact`

Remove **Fun Facts!**.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --remove-fun-fact
```

### `--create-fun-fact [OPTIONS]`

Create a new **Fun Facts! Splashscreen**.

#### Options

* **No arguments**: Create a boot splashscreen. The resulting splashscreen will be in `/home/pi/RetroPie/splashscreens/`.
* `[SYSTEM]`: Create a launching image for a given system. The resulting launching image will be in `/opt/retropie/configs/[SYSTEM]/`). 
* `[SYSTEM]` `[ROM]`: Create a launching image for a given game. The resulting launching image will be in `/home/pi/RetroPie/roms/[SYSTEM]/`).

`[SYSTEM]` can be:

* `all` (will create launching images for all the systems).
* Any system found in `/opt/retropie/configs/`. 

`[ROM]` can be:

* The full path of the ROM (e.g. `/home/pi/RetroPie/megadrive/Sonic The Hedgehog.zip`).
* Just the name **with the file extension** (e.g. `Sonic The Hedgehog.zip`)

Wrap `[ROM]` with double quotes `"`.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --create-fun-fact
```

```bash
sudo ./fun-facts-splashscreens.sh --create-fun-fact megadrive
```

```bash
sudo ./fun-facts-splashscreens.sh --create-fun-fact megadrive "/home/pi/RetroPie/megadrive/Sonic The Hedgehog.zip"
```

```bash
sudo ./fun-facts-splashscreens.sh --create-fun-fact megadrive "Sonic The Hedgehog.zip"
```

### `--edit-config`

Edit the configuration file.

Opens a simple text editor.

When using this option from the terminal, it opens the `nano` text editor. To save the changes, press `ctrl + o` and then press `enter`. To exit, press `ctrl + x`.

When using the GUI, use the `tab` key to select `Save` or `Back`.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --edit-config
```

### `--reset-config`

Reset the configuration file.

Removes all values from the configuration file.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --reset-config
```

### `--restore-defaults`

Restore the default files.

* `retropie-default.png` (default splashscreen)
* `fun-facts-splashscreens-settings.cfg` (default configuration file)
* `fun-facts.txt` (default **Fun Facts!** file)

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --restore-defaults
```

### `--gui`

Start the GUI.

It lets you perform all the functions, but in a more friendly manner.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --gui
```

### `--update`

Update the script.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --update
```

If you're using **Fun Facts! Splashscreens** via **RetroPie-Setup** (if you installed it as a scriptmodule via the [RetroPie-Extra](https://github.com/zerojay/RetroPie-Extra) repository), this function won't work. Scriptmodules have their own update function.

If that's the case, go to:

* Manage packages
* Manage experimental packages
* fun-facts-splashscreens
* Update from source

### `--version`

Show the script version.

#### Example

```bash
sudo ./fun-facts-splashscreens.sh --version
```

## Configuration file

```
# ---------------------------------
# Fun Facts! Splashscreens Settings
# ---------------------------------

# Paths must be absolute (e.g /home/pi/my-awesome-splashscreen.png).
#
# Short list of available colors:
#
# black, white, gray, gray10, gray25, gray50, gray75, gray90,
# pink, red, orange, yellow, green, silver, blue, cyan, purple, brown.
#
# TIP: run the 'convert -list color' command to get a full list.

# -----------------
# Boot splashscreen
# -----------------

# Background image
boot_splashscreen_background_path = ""

# Background solid color
boot_splashscreen_background_color = ""

# Text color
boot_splashscreen_text_color = ""

# Text font
boot_splashscreen_text_font_path = ""

# ----------------
# Launching images
# ----------------

# Background image
launching_images_background_path = ""

# Background solid color
launching_images_background_color = ""

# Text color
launching_images_text_color = ""

# Text font
launching_images_text_font_path = ""

# "Press button" text
launching_images_press_button_text = ""

# "Press button" text color
launching_images_press_button_text_color = ""

# ----------------
# Automate scripts
# ----------------

# Enable/disable script at boot (Boolean: true/false)
boot_splashscreen_script = ""

# Enable/disable launching images (Boolean: true/false)
launching_images_script = ""
```

## Add a new Fun Fact!

* Open [fun-facts.txt](/fun-facts.txt).
* Add a new **Fun Fact!** (see the [style guide](#style-guide)).

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
