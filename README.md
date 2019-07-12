# elm-daterange-picker

A date range picker written in [Elm](https://elm-lang.org/).

## How is this useful?

Default theme:
![](https://i.imgur.com/A7I9AKo.jpg)

If you have questionable tastes, you can do that:
![](https://i.imgur.com/B2acsjG.jpg)

Selecting a date range is a common operation for many Web applications. While
there are offerings in the Elm ecosystem, we couldn't find any ergonomic
equivalent of [daterangepicker](http://www.daterangepicker.com/), which this
package takes a lot of inspiration from.

## Demo

You can look at how this package can be used by browsing this demo code
[here](https://github.com/allo-media/elm-daterange-picker/blob/master/demo/Main.elm).

## Customize styles

By default, we have not defined a font-family, so that the style fits any site.

You can use the [demo.css] file or its [SCSS source] for fine-tuning the
default styles of the datepicker.

The default stylesheet uses CSS variables to help you tweaking most colors used
by the component (just add **your** root colors **after** calling our CSS, and it's done.) :

```CSS
:root {
  --edrp-background-color: #fff;
  --edrp-font-color: rgba(0, 0, 0, 0.8);
  --edrp-primary-color: rgb(82, 143, 255);
  --edrp-primary-color-alpha: rgba(82, 143, 255, 0.25);
  --edrp-border-color: lightgrey;
}
```

## Install

    elm install allo-media/elm-daterange-picker

## Local install

    npm install

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

[demo.css]: https://github.com/allo-media/elm-daterange-picker/blob/master/demo/demo.css
[scss source]: https://github.com/allo-media/elm-daterange-picker/blob/master/style/demo.scss
