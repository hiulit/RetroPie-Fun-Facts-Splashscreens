# Fun Facts Splashscreens for RetroPie

> Not working yet! Well, it's working, but it's not officially released! It's just for testing purposes!

This script creates a splashscreen for RetroPie with a random 'Fun Fact!' to be shown at boot.

An option can be enabled to automatically create a new splashscreen at every boot.

For now, the best way to use the splashscreen created by this script is to use the `Choose Own Splashscreen` option under the **Splashscreen Menu** in **RetroPie settings**. See the [Splashscreen wiki](https://github.com/retropie/retropie-setup/wiki/splashscreen).

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

If no option is passed, you will be prompted with a usage example:

```
USAGE: sudo ./es-fun-facts-splashscreens.sh [options]

Use '--help' to see all the options
```

## Options

* `--help`: Print the help message and exit.
* `--enable-boot`: Enable script to be launch at boot.
* `--disable-boot`: Disable script to be launch at boot.
* `--create-fun-fact`: Create Fun Fact Splashscreen.

## Changelog

### v0.2.0 (November 15th 2017)

#### Added

* Options:
    * `--help`: Print the help message and exit.
    * `--enable-boot`: Enable script to be launch at boot.
    * `--disable-boot`: Disable script to be launch at boot.
    * `--create-fun-fact`: Create Fun Fact Splashscreen.

#### Changed

* If no option is passed, user gets prompted with a usage example.
* To create the Fun Fact Splashscreen, the user must pass `--create-fun-fact` option to the script.

#### Deprecated

* ~~Now the scripts adds the line in `/etc/rc.local` to launch itself at boot automatically.~~ The user must enable this function (launch script at boot) by passing `--enable-boot` option to the script instead of adding it automatically.

### v0.1.0 (November 14th 2017)

* The script creates a splashscreen with random fun facts.
* Now the scripts adds the line in `/etc/rc.local` to launch itself at boot automatically.

## Contributing

First of all, I really appreciate that you're willing to ~~waste~~ spend some time contributing to **Fun Facts Splashscreens**! 🎉👍

You can help make **Fun Facts Splashscreens** better by [reporting issues](#issues) or [contributing code](#pull-requests).

### Issues

[Issues](https://github.com/hiulit/es-fun-facts-splashscreens/issues) can be used not only for bug reporting, but also for suggesting improvements, whether they are code related (cleaner code, modularity, etc.) or feature requests.

#### Guidelines

* Search [previous issues](https://github.com/hiulit/es-fun-facts-splashscreens/issues?utf8=%E2%9C%93&q=is%3Aissue) before creating a new one, as yours may be a duplicate.
* Use a clear and descriptive title for the issue to identify the problem.
* Describe the exact steps which reproduce the problem in as many details as possible.

### Pull requests

[Pull requests](https://help.github.com/articles/creating-a-pull-request/) are most welcomed! 😃

* Fork **Fun Facts Splashscreens**: `git clone git@github.com:your-username/es-fun-facts-splashscreens.git`.
* Create a **new branch** and make the desired changes there.
* [Create a pull request](https://github.com/hiulit/es-fun-facts-splashscreens/pulls).

## Authors

Me 😛 [@hiulit](https://github.com/hiulit).

## Credits

Thanks to:

* [Parviglumis](https://retropie.org.uk/forum/user/parviglumis) - For the idea of creating the [Fun Facts Splashscrenns](https://retropie.org.uk/forum/topic/13630).
* [meleu](https://github.com/meleu/) - For all his help and wisdom with the code :D
* All the people at the [RetroPie Forum](https://retropie.org.uk/forum/).

## License

MIT License

Copyright (c) 2017 Xavier Gómez Gosálbez

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
