# elm-daterange-picker

A date range picker written in [Elm](https://elm-lang.org/) ([Demo](https://allo-media.github.io/elm-daterange-picker/)).

## How is this useful?

Default theme:
![](https://i.imgur.com/A7I9AKo.jpg)

Selecting a date range is a common operation for many Web applications. While
there are offerings in the Elm ecosystem, we couldn't find any ergonomic
equivalent of [daterangepicker](http://www.daterangepicker.com/), which this
package takes a lot of inspiration from.

## Demo

You can look at how this package can be used by browsing this demo code
[here](https://github.com/allo-media/elm-daterange-picker/blob/master/demo/Main.elm).

## Usage

```elm
import DateRangePicker as Picker
import Html exposing (Html)

type alias Model =
    { picker : Picker.State }

type Msg
    = PickerChanged Picker.State

init : ( Model, Cmd Msg )
init =
    let
        picker =
            Picker.init Picker.defaultConfig Nothing
    in
    ( { picker = picker }
    , Picker.now PickerChanged picker
    )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PickerChanged state ->
            { model | picker = state }

view : Model -> Html Msg
view model =
    Picker.view PickerChanged model.picker
```

## Customize styles

By default, we have not defined any default `font-family`, so that the style
fits any app/site.

You can use the [style.css] file or its [SCSS source] as a starting point for
fine-tuning the default styles of the datepicker, which also uses CSS variables
to help you tweaking most colors used by the component; just add your own root
colors **after** calling our CSS, and it's done:

```CSS
:root {
  --edrp-background-color: #fff;
  --edrp-font-color: rgba(0, 0, 0, 0.8);
  --edrp-primary-color: rgb(82, 143, 255);
  --edrp-primary-color-alpha: rgba(82, 143, 255, 0.25);
  --edrp-border-color: lightgrey;
}
```

So if you have questionable tastes, you can eventually obtain this:
![](https://i.imgur.com/B2acsjG.jpg)

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

[style.css]: https://allo-media.github.io/elm-daterange-picker/style.css
[scss source]: https://github.com/allo-media/elm-daterange-picker/blob/master/style/style.scss
