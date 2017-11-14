# Fun Facts Splashscreens for RetroPie

Not working yet! It's just for testing purposes!

## Instalation

```
cd /home/pi/
git clone https://github.com/hiulit/es-fun-facts-splashscreens.git
cd es-fun-facts-splashscreens/
sudo chmod +x es-fun-facts-splashscreens.sh
sudo ./es-fun-facts-splashscreens.sh
```

This should create a new splashscreen in `/home/pi/RetroPie/splashscreens` called `fun-fact-splashscreen.png`.

~~Now, in order to launch the script at boot, you have to edit `/etc/rc.local` and this line `sudo /home/pi/es-fun-facts-splashscreens/es-fun-facts-splashscreens.sh &` just before `exit 0`.~~

~~Remeber to add `&` at the end of the line.~~

The script now adds the line in `/etc/rc.local` to launch itself at boot automatically.

## Changelog

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

* [meleu](https://github.com/meleu/) - For all his help and wisdom :D
* All the people at the [RetroPie Forum](https://retropie.org.uk/forum/)

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
