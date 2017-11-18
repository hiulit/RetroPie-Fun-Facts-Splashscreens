# Fun Facts Splashscreens for RetroPie

> Not working yet! Well, it's working, but it's not officially released! It's just for testing purposes!

This script creates a splashscreen for RetroPie with a random **Fun Fact!™** to be shown at boot.

An option can be enabled to automatically create a new splashscreen at every boot.

For now, the best way to use the splashscreen created by this script is to use the `Choose Own Splashscreen` option under the **Splashscreen Menu** in **RetroPie settings**. See the [Splashscreen wiki](https://github.com/retropie/retropie-setup/wiki/splashscreen).

**This script is to be used with RetroPie in a Raspberry Pi (because splashscreens only work with the Raspberry Pi).**

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

**Example:**

```
sudo ./es-fun-facts-splashscreens.sh --create-fun-fact /home/pi/Downloads/retropie-2014.png black
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
