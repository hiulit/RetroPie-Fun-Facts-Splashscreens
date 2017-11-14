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

This should create create a new splashscreen in `/home/pi/RetroPie/splashscreens` called `fun-fact-splashscreen.png`.

Now, in order to launch the script at boot, you have to edit `/etc/rc.local` and this line `sudo /home/pi/es-fun-facts-splashscreens/es-fun-facts-splashscreens.sh &` just before `exit 0`.

Remeber to add `&` at the end of the line.
