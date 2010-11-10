# StropheCappuccino

## What is StropheCappuccino ?

StropheCappuccino is a set of classes uses to bind the pure Javascript
Strophe Library. This allows to use realtime XMPP in Cappuccino web
application. This Library is used by Archipel Project.
This library is released under LGPL license. Feel
free to use it or improve it.


## Build

To build StropheCappuccino you can type

    # jake debug ; jake release

This will build Strophe from source also. You must first initialise the Strophe.js submodule:

    # git submodule init

The release build will not minify strophe.js. To do this, you must run Resources/Strophe/strophe.js through YUI Compressor after building StropheCappuccino.


## Quick Start

Simply include the StropheCappuccino framework in your Frameworks directory and include StropheCappuccino.js

    @import <StropheCappuccino/StropheCappuccino.j>


## Documentation

To generate the documentation execute the following :

    # jake docs


## Help / Suggestion

You can reach us at irc://irc.freenode.net/#archipel