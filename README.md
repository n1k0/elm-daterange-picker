elm-daterange-picker
====================

A date range picker written in [Elm](https://elm-lang.org/).

## How is this useful?

![](https://i.imgur.com/QGFAv6F.png)

Selecting a date range is a common operation for many Web applications. While
there are offerings in the Elm ecosystem, we couldn't find any equivalent of
[daterangepicker](http://www.daterangepicker.com/), which this package takes a
lot of inspiration from.

## Demo

You can look at how this package can be used by browsing this demo code
[here](https://github.com/allo-media/elm-daterange-picker/blob/master/demo/Main.elm).

## Install

    elm install allo-media/elm-daterange-picker

## Local install

    npm i

## Run the demo

The demo is powered by [elm-live](https://github.com/wking-io/elm-live), meaning
any code changes will trigger a page reload. Neat!

    npm start

Then head to [localhost:3000](http://localhost:3000/) from your browser.

### Hacking on the demo with Atom & Elmjutsu

If you've configured Atom & Elmjutsu to use `./node_modules/.bin/elm` as the
default path to the Elm executable, you'll need a trick for having the compiler
working when editing `demo/Main.elm`:

    mkdir -P demo/node_modules/.bin
    ln -sf ../../../node_modules/.bin/elm demo/node_modules/.bin/elm

## License

MIT
