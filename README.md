# elm-daterange-picker

A date range picker written in [Elm](https://elm-lang.org/) ([Demo](https://n1k0.github.io/elm-daterange-picker/)).

> Note: this package, previously known as `allo-media/elm-daterange-picker`, has moved to `n1k0/elm-daterange-picker`. New versions will be released from there, but starting from `1.0.0`.

## How is this useful?

![](https://i.imgur.com/NL66R88.png)

Selecting a date range is a common operation for many Web applications. While there are offerings in the Elm ecosystem, we couldn't find any ergonomic equivalent of [daterangepicker](http://www.daterangepicker.com/), which this package takes a lot of inspiration from.

## Demo

You can look at how this package can be used by browsing this demo code [here](https://github.com/n1k0/elm-daterange-picker/blob/master/demo/Main.elm).

## Usage

```elm
import Browser
import DateRangePicker as Picker
import Html exposing (Html, text)

type alias Model =
    { picker : Picker.State }

type Msg
    = PickerChanged Picker.State

init : () -> ( Model, Cmd Msg )
init _ =
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
            ( { model | picker = state }, Cmd.none )

view : Model -> Html Msg
view model =
    Picker.view PickerChanged model.picker

main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = .picker >> Picker.subscriptions PickerChanged
        }
```

## Customize styles

By default, we have not defined any default `font-family`, so that the style fits any app/site.

You can use the [style.css] file or its [SCSS source] as a starting point for fine-tuning the default styles of the datepicker, which also uses CSS variables to help you tweaking most colors used by the component; just add your own root colors **after** calling our CSS, and it's done:

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

![](https://i.imgur.com/sbDCvi6.png)

## Install

    elm install n1k0/elm-daterange-picker

## Local install

    npm install

## Run the demo

The demo is powered by [parcel](https://parceljs.org/), meaning any code changes will trigger a page reload. Neat!

    npm start

Then head to [localhost:1234](http://localhost:1234/) from your browser.

## Credits

- [BeardedBear](https://github.com/BeardedBear) for the default styles.
- [Allo-Media](https://www.allo-media.net/) for initially backing up the package development.

## License

MIT

[style.css]: https://github.com/n1k0/elm-daterange-picker/blob/master/demo/style.css
[scss source]: https://github.com/n1k0/elm-daterange-picker/blob/master/demo/style.scss
