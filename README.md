# Fun Facts Splashscreens for RetroPie

> Not working yet! Well, it's working, but it's not officially released! It's just for testing purposes!

This script generates splashscreens for RetroPie with a random **Fun Fact!™**.

**WARNING: Splashscreens are only only available on the Raspberry Pi.**

For now, this is the best way to use the splashscreen created by this script:

* Create a **Fun Fact!™** splashscreen. See the [examples below](#examples).
* Go to the **Splashscreen Menu** (the Splashscreen Menu can be accessed from the RetroPie Menu in EmulationStation or through the setup script under option 3)
* Select the `Choose Own Splashscreen` option. See the [Splashscreen wiki](https://github.com/retropie/retropie-setup/wiki/splashscreen).
* Select the recently created **Fun Fact!™** splashscreen.

## Instalation

```
cd /home/pi/
git clone https://github.com/hiulit/es-fun-facts-splashscreens.git
cd es-fun-facts-splashscreens/
sudo chmod +x es-fun-facts-splashscreens.sh
```

## Usage

```
sudo ./es-fun-facts-splashscreens.sh [options]
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: sudo ./es-fun-facts-splashscreens.sh [options]

Use '--help' to see all the options
```

## Options

* `--help`: Print the help message and exit.
* `--enable-boot`: Enable script to be launch at boot.
    * `$1`: Path to the splashscreen to be used.
    * `$2`: Text color.
* `--disable-boot`: Disable script to be launch at boot.
* `--create-fun-fact`: Create Fun Fact Splashscreen.
    * `$1`: Path to the splashscreen to be used.
    * `$2`: Text color.

If no options are passed to `--create-fun-fact` or `--enable-boot`, the script takes the splashscreen and the text color defaults, `splash4-3.png` and `white`, respectively.

## Examples

### `--help`

Print the help message and exit.

```
sudo ./es-fun-facts-splashscreens.sh --help
```

### `--enable-boot [options]`

Enable script to be launch at boot.

**WARNING: Backing up `/etc/rc.local` it's most recommended before using this option. It could erase important stuff. Use it at your own risk.**

Options:

* `$1`: Path to the splashscreen to be used.
* `$2`: Text color.

```
sudo ./es-fun-facts-splashscreens.sh --enable-boot /home/pi/Downloads/retropie-2014.png black
```

### `--disable-boot`

Disable script to be launch at boot.

**WARNING: Backing up `/etc/rc.local` it's most recommended before using this option. It could erase important stuff. Use it at your own risk.**

```
sudo ./es-fun-facts-splashscreens.sh --disable-boot
```

### `--create-fun-fact`

Create Fun Fact Splashscreen.

Options:

* `$1`: Path to the splashscreen to be used.
* `$2`: Text color.

```
sudo ./es-fun-facts-splashscreens.sh --create-fun-fact /home/pi/Downloads/retropie-2014.png black
```

## Changelog

See [CHANGELOG](/CHANGELOG.md).

## Contributing

See [CONTRIBUTING](/CONTRIBUTING.md).

## Authors

Me 😛 [@hiulit](https://github.com/hiulit).

## Credits

Thanks to:

* [Parviglumis](https://retropie.org.uk/forum/user/parviglumis) - For the idea of creating the [Fun Facts Splashscreens](https://retropie.org.uk/forum/topic/13630).
* [meleu](https://github.com/meleu/) - For all his help and wisdom with the code :D
* All the people at the [RetroPie Forum](https://retropie.org.uk/forum/).

## License

[MIT License](/LICENSE).
