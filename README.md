# RepRapOnRails - a stand-alone, touch-based RepRap host controller

Developed for the Kühling&Kühling RepRap Industrial 3D printer, this is the
system that provides both its integrated touchscreen interface as well as a backend
browser-access via ethernet to upload printjobs to the machine.

All information about the machine, build instructions and such will be published at
[http://kuehlingkuehling.de](http://kuehlingkuehling.de).

## Target Hardware

This Ruby-on-Rails app is meant to run on a BeagleBone Black (BBB) minicomputer with Debian
Wheezy operating system and 10inch touchscreen attached. A RUMBA RepRap microcontroller-
board is connected via USB and the BBB connects to your local network via wired ethernet.

## RepRap Microcontroller Firmware

The app makes use of some features only provided by the [Repetier Firmware](https://github.com/repetier/Repetier-Firmware).

## Software Layout

Upon start of the rails server, a persistent serial connection is established to the RepRap
microcontroller through a RepRapHost instance (lib/repraphost.rb).
Additionally two AngularJS web apps are provided:

* http://localhost/touchapp

  The touchscreen interface  - only accessible from localhost (via chromium browser in
kiosk mode)

* http://YOUR-BBB-HOSTNAME>/

  A backend interface available from the network to upload and manage printjobs

Find the AngularJS sources of these in app/assets/javascripts/touchapp and app/assets/javascripts/backendapp

Communication between the AngularJS apps in the browser and the Rails server is done via websocket connections for live updates in both directions.

## Database

Due to quite some concurrency through parallel ruby threads, an appropriate database server like mysql or postgresql is necessary.

## Credits

RepRapOnRails stands on the shoulders of exceptionally awesome open source software used in this project:

* Ruby-on-Rails - of course!
  [http://rubyonrails.org/](http://rubyonrails.org/)

* Twitter Bootstrap 3.0 
  [http://getbootstrap.com/](http://getbootstrap.com/)

* Font Awsome Icons
  [http://fortawesome.github.io/Font-Awesome/](http://fortawesome.github.io/Font-Awesome/)

* websocket-rails
  [https://github.com/websocket-rails/websocket-rails](https://github.com/websocket-rails/websocket-rails)

* rails-settings-cached
  [https://github.com/huacnlee/rails-settings-cached](https://github.com/huacnlee/rails-settings-cached)

* jQuery
  [http://jquery.com/](http://jquery.com/)

* AngularJS
  [http://angularjs.org/](http://angularjs.org/)

* Angular UI Bootstrap
  [http://angular-ui.github.io/bootstrap/](http://angular-ui.github.io/bootstrap/)

## Current Version

v1.0

## Author

Under the umbrella of Kühling&Kühling GbR this software was developed by

* Jonas Kühling <mail@jonaskuehling.de>
* Simon Kühling <mail@simonkuehling.de>

## License

This work is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License. 
To view a copy of this license, visit 
[http://creativecommons.org/licenses/by-sa/4.0/](http://creativecommons.org/licenses/by-sa/4.0/) or 
send a letter to Creative Commons, 444 Castro Street,
Suite 900, Mountain View, California, 94041, USA.