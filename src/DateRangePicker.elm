module DateRangePicker exposing
    ( Config, defaultConfig, configure, reconfigure
    , State, init, now, nowTask, getRange, setRange, setToday, disable, isDisabled, open, isOpened
    , view
    , subscriptions
    )

{-| A date range picker widget.

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


# Configuration

@docs Config, defaultConfig, configure, reconfigure


# State

@docs State, init, now, nowTask, getRange, setRange, setToday, disable, isDisabled, open, isOpened


# View

@docs view


# Subscriptions

@docs subscriptions

-}

import Browser.Events as BE
import DateRangePicker.Calendar as Calendar
import DateRangePicker.Helpers as Helpers
import DateRangePicker.Range as Range exposing (Range)
import DateRangePicker.Step as Step exposing (Step)
import Html exposing (..)
import Html.Attributes as HA exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Task exposing (Task)
import Time exposing (Posix)
import Time.Extra as TE


{-| DateRangePicker configuration:

  - `allowFuture`: Allow picking a range in the future
  - `applyRangeImmediately`: Apply predefined range immediately when clicked
  - `class`: CSS class name(s) to add to the component root element.
  - `inputClass`: CSS class name(s) to add to the component text input.
  - `monthFormatter`: How to format a [`Time.Month`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months)
  - `noRangeCaption`: The String to render when no range is set
  - `predefinedRanges`: Generates custom predefined ranges.
  - `sticky`: Make the picker always opened
  - `translations` : Allow provide translations
  - `weekdayFormatter`: How to format a [`Time.Weekday`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months)
  - `weeksStartOn`: The [`Time.Weekday`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months) weeks start on (eg. `Time.Mon` or `Time.Sun`)
  - `zone`: A user [`Time.Zone`](https://package.elm-lang.org/packages/elm/time/latest/Time#Zone) to compute relative datetimes against (default: `Time.utc`)

-}
type alias Config =
    { allowFuture : Bool
    , applyRangeImmediately : Bool
    , class : String
    , inputClass : String
    , monthFormatter : Time.Month -> String
    , noRangeCaption : String
    , predefinedRanges : Time.Zone -> Posix -> List ( String, Range )
    , sticky : Bool
    , translations : Calendar.Translations
    , weekdayFormatter : Time.Weekday -> String
    , weeksStartOn : Time.Weekday
    , zone : Time.Zone
    }


{-| A [`Config`](#Config) featuring the following default values:

  - `allowFuture`: `True`
  - `applyRangeImmediately`: `True`
  - `class`: `""`
  - `inputClass`: `""`
  - `monthFormatter`: Converts month names to their 3 chars English equivalent: `Jan`, `Feb`, etc.
  - `noRangeCaption`: `"N/A"`
  - `predefinedRanges`: `"Today"`, `"Yesterday"`, `"Last 7 days"`, `"Last 30 days"`, `"This month"` and `"Last month"`
  - `sticky`: `False`
  - `translations`: `{ close: "Close", clear: "Clear", apply: "Apply", pickStart: "Hint: pick a start date", pickEnd: "Hint: pick an end date" }`
  - `weekdayFormatter`: Converts weekday names to their 2 chars English equivalent: `Mo`, `Tu`, etc.
  - `weeksStartOn`: `Time.Mon` (weeks start on Monday)

-}
defaultConfig : Config
defaultConfig =
    { allowFuture = True
    , applyRangeImmediately = True
    , class = ""
    , inputClass = ""
    , monthFormatter = Helpers.monthToString
    , noRangeCaption = "N/A"
    , predefinedRanges = defaultPredefinedRanges
    , sticky = False
    , translations = defaultTranslations
    , weekdayFormatter = Helpers.weekdayToString
    , weeksStartOn = Time.Mon
    , zone = Time.utc
    }


{-| Helper to selectively alter [`defaultConfig`](#defaultConfig):

    configure (\default -> { default | weeksStartOn = Time.Sun })
        |> init Nothing

-}
configure : (Config -> Config) -> Config
configure updater =
    updater defaultConfig


{-| Reconfigure a date range picker [`State`](#State).

    state |> reconfigure (\current -> { current | weeksStartOn = Time.Sun })

-}
reconfigure : (Config -> Config) -> State -> State
reconfigure updater (State ({ config } as internal)) =
    State { internal | config = updater config }


{-| DateRangePicker state.

Use helpers to set or retrieve values out of it.

-}
type State
    = State InternalState


type alias InternalState =
    { config : Config
    , current : Maybe Range
    , disabled : Bool
    , hovered : Maybe Posix
    , leftCal : Posix
    , rightCal : Posix
    , opened : Bool
    , today : Posix
    , step : Step
    }


type Msg
    = Apply (Maybe Range)
    | Clear
    | Close
    | Hover Posix
    | Next
    | NoOp
    | Open
    | Prev
    | Pick Posix
    | Set Range


{-| Initializes a State from a [`Config`](#Config) and an initial
[`Range`](./DateRangePicker-Range#Range).

Note: this will position the calendar at Unix Epoch (Jan, 1st 1970 UTC). To
position it at today's date, look at [`now`](#now) and [`nowTask`](#nowTask).

-}
init : Config -> Maybe Range -> State
init config selected =
    let
        ( leftCal, rightCal ) =
            getCalendars config selected TE.epoch
    in
    State
        { config = config
        , current = selected
        , disabled = False
        , hovered = Nothing
        , leftCal = leftCal
        , rightCal = rightCal
        , opened = False
        , step = Step.fromMaybe selected
        , today = TE.epoch
        }


{-| A command for positioning a [`State`](#State) at today's date.
-}
now : (State -> msg) -> State -> Cmd msg
now toMsg (State internal) =
    nowTask internal.config internal.current
        |> Task.perform toMsg


{-| A Task for initializing a [`State`](#State) with an initial
[`Range`](./DateRangePicker-Range#Range) at today's date.
-}
nowTask : Config -> Maybe Range -> Task Never State
nowTask config selected =
    Time.now
        |> Task.andThen (\today -> init config selected |> setToday today |> Task.succeed)


{-| Get the current [`Range`](./DateRangePicker-Range#Range) from a [`State`](#State), if any.
-}
getRange : State -> Maybe Range
getRange (State { current }) =
    current


{-| Assign a selected [`Range`](./DateRangePicker-Range#Range) to the DateRangePicker.
-}
setRange : Maybe Range -> State -> State
setRange dateRange (State internal) =
    State { internal | current = dateRange, step = Step.fromMaybe dateRange }


{-| Positions a date range picker [`State`](#State) to current date.
-}
setToday : Posix -> State -> State
setToday today (State internal) =
    let
        ( newLeftCal, newRightCal ) =
            getCalendars internal.config internal.current today
    in
    State
        { internal
            | leftCal = newLeftCal
            , rightCal = newRightCal
            , today = today
        }


{-| Checks if the date range picker [`State`](#State) is currently disabled.
-}
isDisabled : State -> Bool
isDisabled (State { disabled }) =
    disabled


{-| Checks if the date range picker [`State`](#State) is currently opened.

Note: always returns `True` when the `sticky` config option is enabled.

-}
isOpened : State -> Bool
isOpened (State { config, opened }) =
    config.sticky || opened


{-| Disable or enable a date range picker [`State`](#State).
-}
disable : Bool -> State -> State
disable disabled (State internal) =
    State { internal | disabled = disabled }


{-| Open or close a date range picker [`State`](#State).

Note: inoperant when the `sticky` option is `True`.

-}
open : Bool -> State -> State
open opened (State internal) =
    State
        { internal
            | opened =
                if internal.config.sticky then
                    False

                else
                    opened
        }


getCalendars : Config -> Maybe Range -> Posix -> ( Posix, Posix )
getCalendars { allowFuture, zone } maybeRange today =
    case ( allowFuture, maybeRange ) of
        ( True, Just range ) ->
            ( range |> Range.beginsAt |> TE.startOfMonth zone
            , range |> Range.beginsAt |> Helpers.startOfNextMonth zone
            )

        ( False, Just range ) ->
            ( range |> Range.endsAt |> TE.addDaysZ -1 zone |> TE.addMillis 1 |> Helpers.startOfPreviousMonth zone
            , range |> Range.endsAt |> TE.startOfMonth zone
            )

        ( _, Nothing ) ->
            ( today |> Helpers.startOfPreviousMonth zone
            , today |> TE.startOfMonth zone
            )


update : Msg -> InternalState -> InternalState
update msg ({ leftCal, rightCal, step } as internal) =
    case msg of
        Apply dateRange ->
            let
                ( newLeftCal, newRightCal ) =
                    getCalendars internal.config dateRange internal.today
            in
            { internal
                | opened = False
                , leftCal = newLeftCal
                , rightCal = newRightCal
                , current = dateRange
                , step = Step.fromMaybe dateRange
            }

        Clear ->
            { internal
                | opened = False
                , current = Nothing
                , step = Step.fromMaybe Nothing
            }

        Close ->
            { internal
                | opened = False
                , step = Step.fromMaybe internal.current
            }

        Hover posix ->
            { internal
                | hovered =
                    case step of
                        Step.Begin _ ->
                            Just posix

                        _ ->
                            Nothing
            }

        Next ->
            { internal
                | leftCal = rightCal
                , rightCal = Helpers.startOfNextMonth internal.config.zone rightCal
            }

        NoOp ->
            internal

        Open ->
            let
                ( newLeftCal, newRightCal ) =
                    getCalendars internal.config internal.current internal.today
            in
            { internal
                | opened = True
                , leftCal = newLeftCal
                , rightCal = newRightCal
            }

        Pick picked ->
            { internal | step = step |> Step.next internal.config.zone picked }

        Prev ->
            { internal
                | leftCal = leftCal |> Helpers.startOfPreviousMonth internal.config.zone
                , rightCal = leftCal
            }

        Set dateRange ->
            let
                ( newLeftCal, newRightCal ) =
                    getCalendars internal.config (Just dateRange) internal.today
            in
            { internal
                | leftCal = newLeftCal
                , rightCal = newRightCal
                , step = Step.fromMaybe (Just dateRange)
            }


handleEvent : (State -> msg) -> Msg -> InternalState -> msg
handleEvent toMsg msg =
    update msg >> State >> toMsg


defaultTranslations : Calendar.Translations
defaultTranslations =
    { close = "Close"
    , clear = "Clear"
    , apply = "Apply"
    , pickStart = "Hint: pick a start date"
    , pickEnd = "Hint: pick an end date"
    }


defaultPredefinedRanges : Time.Zone -> Posix -> List ( String, Range )
defaultPredefinedRanges zone today =
    let
        daysBefore n posix =
            posix |> TE.addDays -n |> TE.startOfDay zone
    in
    [ ( "Today"
      , Range.create zone (TE.startOfDay zone today) (TE.endOfDay zone today)
      )
    , ( "Yesterday"
      , Range.create zone (today |> daysBefore 1 |> TE.startOfDay zone) (today |> daysBefore 1 |> TE.endOfDay zone)
      )
    , ( "Last 7 days"
      , Range.create zone (today |> daysBefore 7) (today |> TE.startOfDay zone |> TE.addMillis -1)
      )
    , ( "Last 30 days"
      , Range.create zone (today |> daysBefore 30) (today |> TE.startOfDay zone |> TE.addMillis -1)
      )
    , ( "This month"
      , Range.create zone (today |> TE.startOfMonth zone) today
      )
    , ( "Last month"
      , Range.create zone (today |> Helpers.startOfPreviousMonth zone) (today |> TE.startOfMonth zone |> TE.addMillis -1)
      )
    ]


predefinedRangesView : (State -> msg) -> InternalState -> Html msg
predefinedRangesView toMsg ({ config, step, today } as internal) =
    let
        entry ( name, range ) =
            li
                [ classList
                    [ ( "EDRPPresets__label", True )
                    , ( "EDRPPresets__label--active", Step.toMaybe step == Just range )
                    ]
                , if config.applyRangeImmediately then
                    onClick <| handleEvent toMsg (Apply (Just range)) internal

                  else
                    onClick <| handleEvent toMsg (Set range) internal
                ]
                [ text name ]
    in
    div [ class "EDRPPresets" ]
        [ today
            |> internal.config.predefinedRanges config.zone
            |> List.map entry
            |> ul [ class "EDRPPresets__list" ]
        ]


panel : (State -> msg) -> State -> Html msg
panel toMsg (State internal) =
    let
        baseCalendar =
            { allowFuture = internal.config.allowFuture
            , hover = \posix -> handleEvent toMsg (Hover posix) internal
            , hovered = internal.hovered
            , monthFormatter = internal.config.monthFormatter
            , next = Nothing
            , noOp = handleEvent toMsg NoOp internal
            , pick = \posix -> handleEvent toMsg (Pick posix) internal
            , prev = Nothing
            , step = internal.step
            , target = internal.today
            , translations = internal.config.translations
            , today = internal.today
            , weekdayFormatter = internal.config.weekdayFormatter
            , weeksStartOn = internal.config.weeksStartOn
            , zone = internal.config.zone
            }

        allowNext =
            internal.config.allowFuture
                || (internal.rightCal |> TE.startOfMonth internal.config.zone |> Time.posixToMillis)
                < (internal.today |> TE.startOfMonth internal.config.zone |> Time.posixToMillis)

        onMouseUp msg =
            custom "mouseup"
                (Decode.succeed
                    { message = msg
                    , preventDefault = True
                    , stopPropagation = True
                    }
                )
    in
    div
        [ classList
            [ ( "EDRP__body", True )
            , ( "EDRP__body--sticky", internal.config.sticky )
            ]
        , onMouseUp <| handleEvent toMsg NoOp internal
        ]
        [ div [ class "EDRP__selectors" ]
            [ predefinedRangesView toMsg internal
            , Calendar.view
                { baseCalendar
                    | target = internal.leftCal
                    , prev = Just (handleEvent toMsg Prev internal)
                }
            , Calendar.view
                { baseCalendar
                    | target = internal.rightCal
                    , next =
                        if allowNext then
                            Just (handleEvent toMsg Next internal)

                        else
                            Nothing
                }
            ]
        , div [ class "EDRPFoot" ]
            [ span []
                [ case internal.step of
                    Step.Initial ->
                        text baseCalendar.translations.pickStart

                    Step.Begin _ ->
                        text baseCalendar.translations.pickStart

                    Step.Complete range ->
                        range |> Range.format internal.config.zone |> text
                ]
            , div [ class "EDRPFoot__actions" ]
                [ if not internal.config.sticky then
                    button
                        [ class "EDRP__button"
                        , type_ "button"
                        , onClick <| handleEvent toMsg Close internal
                        ]
                        [ text baseCalendar.translations.close ]

                  else
                    text ""
                , button
                    [ class "EDRP__button"
                    , type_ "button"
                    , HA.disabled (internal.step == Step.Initial)
                    , onClick <| handleEvent toMsg Clear internal
                    ]
                    [ text baseCalendar.translations.clear ]
                , button
                    [ class "EDRP__button EDRP__button--primary"
                    , type_ "button"
                    , onClick <| handleEvent toMsg (Apply (Step.toMaybe internal.step)) internal
                    ]
                    [ text baseCalendar.translations.apply ]
                ]
            ]
        ]


{-| The main DateRangePicker view.

The first argument is tipycally one of your application `Msg`, which will receive
a new [`State`](#State) each time it's changed:

    import DateRangePicker as Picker

    type alias Model =
        { picker : Picker.State }

    type Msg
        = PickerChanged Picker.State

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            PickerChanged state ->
                { model | picker = state }

    view : Model -> Html Msg
    view model =
        Picker.view PickerChanged model.picker

-}
view : (State -> msg) -> State -> Html msg
view toMsg (State internal) =
    div [ "EDRP " ++ internal.config.class |> String.trim |> class ]
        [ input
            [ type_ "text"
            , "EDRP__input " ++ internal.config.inputClass |> String.trim |> class
            , HA.disabled internal.disabled
            , internal.current
                |> Maybe.map (Range.format internal.config.zone)
                |> Maybe.withDefault internal.config.noRangeCaption
                |> value
            , onClick <| handleEvent toMsg Open internal
            , readonly True
            ]
            []
        , if internal.config.sticky || internal.opened then
            panel toMsg (State internal)

          else
            text ""
        ]


{-| DateRangePicker subscriptions. They're useful if you want an opened date range picker
panel to be closed when clicking outside of it.
-}
subscriptions : (State -> msg) -> State -> Sub msg
subscriptions toMsg (State internal) =
    if internal.opened && not internal.config.sticky then
        BE.onMouseUp (Decode.succeed (handleEvent toMsg Close internal))

    else
        Sub.none
