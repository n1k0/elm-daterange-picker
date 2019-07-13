module Main exposing (main)

import Browser
import DateRangePicker as Picker
import DateRangePicker.Helpers as Helpers
import DateRangePicker.Range as Range exposing (Range)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Task exposing (Task)
import Time


type alias Model =
    { config : Picker.Config
    , picker : Picker.State
    }


type Msg
    = PickerChanged Picker.State
    | UpdateConfig Picker.Config


init : () -> ( Model, Cmd Msg )
init _ =
    Picker.configure
        (\default ->
            { default
                | allowFuture = False
                , noRangeCaption = "Click me!"
            }
        )
        |> initFromConfig


initFromConfig : Picker.Config -> ( Model, Cmd Msg )
initFromConfig config =
    let
        picker =
            Picker.init config Nothing
    in
    ( { config = config, picker = picker }
    , Picker.now PickerChanged picker
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PickerChanged state ->
            ( { model | picker = state }, Cmd.none )

        UpdateConfig config ->
            initFromConfig config


view : Model -> Html Msg
view { config, picker } =
    let
        field children =
            p [] [ label [] children ]
    in
    div []
        [ h1 [] [ text "elm-daterange-picker" ]
        , Picker.view PickerChanged picker
        , h2 [] [ text "Live configuration" ]
        , p []
            [ text "Selected: "
            , case Picker.getRange picker of
                Just range ->
                    text (Range.format Time.utc range)

                Nothing ->
                    text "nothing selected"
            ]
        , div []
            [ field
                [ input
                    [ type_ "checkbox"
                    , onCheck (\allow -> UpdateConfig { config | allowFuture = allow })
                    , checked config.allowFuture
                    ]
                    []
                , text " Allow future"
                ]
            , field
                [ input
                    [ type_ "checkbox"
                    , onCheck (\allow -> UpdateConfig { config | applyRangeImmediately = allow })
                    , checked config.applyRangeImmediately
                    ]
                    []
                , text " Apply predefined range immediately"
                ]
            , field
                [ text "No range caption "
                , input
                    [ type_ "text"
                    , onInput (\caption -> UpdateConfig { config | noRangeCaption = caption })
                    , value config.noRangeCaption
                    ]
                    []
                ]
            , field
                [ input
                    [ type_ "checkbox"
                    , onCheck (\sticky -> UpdateConfig { config | sticky = sticky })
                    , checked config.sticky
                    ]
                    []
                , text " Sticky (always opened)"
                ]
            , field
                [ text "Weeks start on "
                , [ Time.Sat, Time.Sun, Time.Mon ]
                    |> List.map
                        (\day ->
                            option
                                [ value (dayToString day)
                                , selected (day == config.weeksStartOn)
                                ]
                                [ text (dayToString day) ]
                        )
                    |> select [ onInput (\str -> UpdateConfig { config | weeksStartOn = dayFromString str }) ]
                ]
            ]
        ]


dayToString : Time.Weekday -> String
dayToString day =
    case day of
        Time.Sun ->
            "Sunday"

        Time.Mon ->
            "Monday"

        Time.Tue ->
            "Tuesday"

        Time.Wed ->
            "Wednesday"

        Time.Thu ->
            "Thursday"

        Time.Fri ->
            "Friday"

        Time.Sat ->
            "Saturday"


dayFromString : String -> Time.Weekday
dayFromString string =
    case string of
        "Sunday" ->
            Time.Sun

        "Monday" ->
            Time.Mon

        "Tuesday" ->
            Time.Tue

        "Wednesday" ->
            Time.Wed

        "Thursday" ->
            Time.Thu

        "Friday" ->
            Time.Fri

        _ ->
            Time.Sat


subscriptions : Model -> Sub Msg
subscriptions { picker } =
    Picker.subscriptions PickerChanged picker


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
