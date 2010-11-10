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

If you wish to build the release version of StropheCappuccino, you will need to have YUI Compressor, and export
the path to yui-compressor-xxx.jar in your shell config as YUI_COMPRESSOR.


## Quick Start

Simply include the StropheCappuccino framework in your Frameworks directory and include StropheCappuccino.js

    @import <StropheCappuccino/StropheCappuccino.j>


## Documentation

To generate the documentation execute the following :

    # jake docs


## Help / Suggestion

You can reach us at irc://irc.freenode.net/#archipel