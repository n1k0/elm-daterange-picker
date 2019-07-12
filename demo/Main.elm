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
    let
        config =
            Picker.configure (\default -> { default | allowFuture = False })
    in
    ( { config = config
      , picker = Picker.init config Nothing (Time.millisToPosix 0)
      }
    , Picker.initToday config Nothing
        |> Task.perform PickerChanged
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PickerChanged state ->
            ( { model | picker = state }, Cmd.none )

        UpdateConfig config ->
            ( model
            , Picker.initToday config (Picker.getValue model.picker)
                |> Task.perform PickerChanged
            )


view : Model -> Html Msg
view { config, picker } =
    div []
        [ p []
            [ text "Selected: "
            , case Picker.getValue picker of
                Just range ->
                    text (Range.format Time.utc range)

                Nothing ->
                    text "nothing selected"
            ]
        , div []
            [ p []
                [ label []
                    [ input [ type_ "checkbox", onCheck (\allow -> UpdateConfig { config | allowFuture = allow }) ] []
                    , text " Allow future"
                    ]
                ]
            , p []
                [ label []
                    [ input [ type_ "checkbox", onCheck (\allow -> UpdateConfig { config | applyRangeImmediately = allow }) ] []
                    , text " Apply predefined range immediately"
                    ]
                ]
            , p []
                [ label []
                    [ text "No range caption "
                    , input [ type_ "text", onInput (\caption -> UpdateConfig { config | noRangeCaption = caption }) ] []
                    ]
                ]
            , p []
                [ label []
                    [ text "Weeks start on "
                    , [ Time.Sat, Time.Sun, Time.Mon ]
                        |> List.map
                            (\day ->
                                option [ value (dayToString day), selected (day == config.weeksStartOn) ] [ text (dayToString day) ]
                            )
                        |> select [ onInput (\str -> UpdateConfig { config | weeksStartOn = dayFromString str }) ]
                    ]
                ]
            ]

        -- , Picker.view PickerChanged picker
        , Picker.panel PickerChanged picker
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
