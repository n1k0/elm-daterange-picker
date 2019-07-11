module DateRangePicker exposing
    ( Config, configure, defaultConfig
    , State, init, initToday, getValue, disable, isDisabled, open, isOpened, setRange
    , view, panel
    , subscriptions
    )

{-| A configurable date range picker widget.


# Configuration

@docs Config, configure, defaultConfig


# State

@docs State, init, initToday, getValue, disable, isDisabled, open, isOpened, setRange


# View

@docs view, panel


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
import Time exposing (Posix, utc)
import Time.Extra as TE


{-| DateRangePicker configuration:

  - `allowFuture`: Allow picking a range in the future
  - `applyRangeImmediately`: Apply predefined range immediately when clicked
  - `weekdayFormatter`: How to format a [`Time.Weekday`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months)
  - `monthFormatter`: How to format a [`Time.Month`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months)
  - `noRangeCaption`: The String to render when no range is set
  - `weeksStartOn`: The [`Time.Weekday`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months) weeks start on (eg. `Time.Mon` or `Time.Sun`)

-}
type alias Config =
    { allowFuture : Bool
    , applyRangeImmediately : Bool
    , weekdayFormatter : Time.Weekday -> String
    , monthFormatter : Time.Month -> String
    , noRangeCaption : String
    , weeksStartOn : Time.Weekday
    }


{-| A Config featuring the following default values:

    { allowFuture = True
    , applyRangeImmediately = True
    , weekdayFormatter = Helpers.weekdayToString
    , monthFormatter = Helpers.monthToString
    , noRangeCaption = "N/A"
    , weeksStartOn = Time.Mon
    }

-}
defaultConfig : Config
defaultConfig =
    { allowFuture = True
    , applyRangeImmediately = True
    , weekdayFormatter = Helpers.weekdayToString
    , monthFormatter = Helpers.monthToString
    , noRangeCaption = "N/A"
    , weeksStartOn = Time.Mon
    }


{-| Helper for selectively altering defaultConfig:

    configure (\default -> { default | weeksStartOn = Time.Sun })
        |> init Nothing

-}
configure : (Config -> Config) -> Config
configure updater =
    updater defaultConfig


{-| DateRangePicker state.

Use helpers to set or retrieve values out of it.

-}
type State
    = State InternalState


type alias InternalState =
    { config : Config
    , current : Maybe Range
    , disabled : Bool
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
    | Next
    | Open
    | Prev
    | Pick Posix
    | Set Range


{-| Initializes a State with the current day represented as a Posix.

    import Time

    init defaultConfig Nothing (Time.millisToPosix 0)

-}
init : Config -> Maybe Range -> Posix -> State
init config selected today =
    let
        ( leftCal, rightCal ) =
            getCalendars config selected today
    in
    State
        { config = config
        , current = selected
        , disabled = False
        , leftCal = leftCal
        , rightCal = rightCal
        , opened = False
        , step = Step.fromMaybe selected
        , today = today
        }


{-| Initializes a State using a Task for fetching today's date.

    import Task

    type Msg
      = DateRangePickerCreated State

    initToday defaultConfig Nothing
      |> Task.perform DateRangePickerCreated

-}
initToday : Config -> Maybe Range -> Task Never State
initToday config selected =
    Time.now |> Task.andThen (init config selected >> Task.succeed)


getCalendars : Config -> Maybe Range -> Posix -> ( Posix, Posix )
getCalendars config maybeRange today =
    case ( config.allowFuture, maybeRange ) of
        ( True, Just { begin } ) ->
            ( begin |> TE.startOfMonth utc
            , begin |> Helpers.startOfNextMonth utc
            )

        ( False, Just { end } ) ->
            ( end |> Helpers.startOfPreviousMonth utc
            , end |> TE.startOfMonth utc
            )

        ( _, Nothing ) ->
            ( today |> Helpers.startOfPreviousMonth utc
            , today |> TE.startOfMonth utc
            )


{-| Get the current DateRangePicker.Range of the DateRangePicker, if any.
-}
getValue : State -> Maybe Range
getValue (State internal) =
    internal.current


{-| Checks if the DateRangePicker is currently disabled.
-}
isDisabled : State -> Bool
isDisabled (State internal) =
    internal.disabled


{-| Checks if the DateRangePicker is currently opened.
-}
isOpened : State -> Bool
isOpened (State internal) =
    internal.opened


{-| Disable or enable a DateRangePicker.
-}
disable : Bool -> State -> State
disable disabled (State internal) =
    State { internal | disabled = disabled }


{-| Open or close a DateRangePicker.
-}
open : Bool -> State -> State
open opened (State internal) =
    State { internal | opened = opened }


{-| Assign a DateRangePicker.Range value to the DateRangePicker.

    import DateRangePicker.Range exposing (Range)

    state |> setRange (Range begin end)

-}
setRange : Maybe Range -> State -> State
setRange dateRange (State internal) =
    State { internal | current = dateRange, step = Step.fromMaybe dateRange }


update : Msg -> InternalState -> InternalState
update msg ({ leftCal, rightCal, step } as internal) =
    case msg of
        Apply dateRange ->
            { internal
                | opened = False
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

        Next ->
            { internal
                | leftCal = rightCal
                , rightCal = Helpers.startOfNextMonth utc rightCal
            }

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
            { internal | step = step |> Step.next picked }

        Prev ->
            { internal
                | leftCal = leftCal |> Helpers.startOfPreviousMonth utc
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
handleEvent tagger msg =
    update msg >> State >> tagger


defaultPredefinedRanges : Posix -> List ( String, Range )
defaultPredefinedRanges today =
    let
        daysBefore n posix =
            posix |> TE.addDays -n |> TE.startOfDay utc
    in
    [ ( "Today"
      , { begin = TE.startOfDay utc today
        , end = TE.endOfDay utc today
        }
      )
    , ( "Yesterday"
      , { begin = today |> daysBefore 1 |> TE.startOfDay utc
        , end = today |> daysBefore 1 |> TE.endOfDay utc
        }
      )
    , ( "Last 7 days"
      , { begin = today |> daysBefore 7
        , end = today |> TE.startOfDay utc |> TE.addMillis -1
        }
      )
    , ( "Last 30 days"
      , { begin = today |> daysBefore 30
        , end = today |> TE.startOfDay utc |> TE.addMillis -1
        }
      )
    , ( "This month"
      , { begin = today |> TE.startOfMonth utc
        , end = today
        }
      )
    , ( "Last month"
      , { begin = today |> Helpers.startOfPreviousMonth utc
        , end = today |> TE.startOfMonth utc |> TE.addMillis -1
        }
      )
    ]


predefinedRangesView : (State -> msg) -> InternalState -> Html msg
predefinedRangesView tagger ({ config, step, today } as internal) =
    let
        entry ( name, range ) =
            li
                [ classList [ ( "active", Step.toMaybe step == Just range ) ]
                , if config.applyRangeImmediately then
                    onClick <| handleEvent tagger (Apply (Just range)) internal

                  else
                    onClick <| handleEvent tagger (Set range) internal
                ]
                [ text name ]
    in
    div [ class "ranges" ]
        [ today
            |> defaultPredefinedRanges
            |> List.map entry
            |> ul []
        ]


{-| A DateRangePicker panel view.

The panel is the content of the window containing the ranges and the two calendars.
This is useful when you don't need to deal with the clickable date input.

Usage is similar to [`view`](#view).

-}
panel : (State -> msg) -> State -> Html msg
panel tagger (State internal) =
    div
        [ class "daterangepicker ltr show-ranges show-calendar opensright" ]
        [ predefinedRangesView tagger internal
        , Calendar.view
            { allowFuture = internal.config.allowFuture
            , weeksStartOn = internal.config.weeksStartOn
            , pick = \posix -> handleEvent tagger (Pick posix) internal
            , next = Nothing
            , prev = Just (handleEvent tagger Prev internal)
            , step = internal.step
            , target = internal.leftCal
            , today = internal.today
            , weekdayFormatter = internal.config.weekdayFormatter
            , monthFormatter = internal.config.monthFormatter
            }
        , Calendar.view
            { allowFuture = internal.config.allowFuture
            , weeksStartOn = internal.config.weeksStartOn
            , pick = \posix -> handleEvent tagger (Pick posix) internal
            , next = Just (handleEvent tagger Next internal)
            , prev = Nothing
            , step = internal.step
            , target = internal.rightCal
            , today = internal.today
            , weekdayFormatter = internal.config.weekdayFormatter
            , monthFormatter = internal.config.monthFormatter
            }
        , div [ class "drp-buttons" ]
            [ span [ class "drp-selected" ]
                [ case internal.step of
                    Step.Initial ->
                        text "Hint: pick a start date"

                    Step.Begin _ ->
                        text "Hint: pick an end date"

                    Step.Complete range ->
                        range |> Range.format utc |> text
                ]
            , button
                [ class "cancelBtn btn btn-sm btn-default"
                , type_ "button"
                , onClick <| handleEvent tagger Close internal
                ]
                [ text "Close" ]
            , button
                [ class "cancelBtn btn btn-sm btn-default"
                , type_ "button"
                , HA.disabled (internal.step == Step.Initial)
                , onClick <| handleEvent tagger Clear internal
                ]
                [ text "Clear" ]
            , button
                [ class "applyBtn btn btn-sm btn-primary"
                , type_ "button"
                , onClick <| handleEvent tagger (Apply (Step.toMaybe internal.step)) internal
                ]
                [ text "Apply" ]
            ]
        ]


{-| The main DateRangePicker view.

If you only need the panel content, have a look at [`panel`](#panel).

-}
view : (State -> msg) -> State -> Html msg
view tagger (State internal) =
    -- FIXME: no inline style if possible
    div [ style "position" "relative" ]
        [ input
            [ class "InputText fullWidth date-range"
            , type_ "text"
            , HA.disabled internal.disabled
            , Step.toMaybe internal.step
                |> Maybe.map (Range.format utc)
                |> Maybe.withDefault internal.config.noRangeCaption
                |> value
            , onClick <| handleEvent tagger Open internal
            , readonly True
            ]
            []
        , if internal.opened then
            panel tagger (State internal)

          else
            text ""
        ]


{-| DateRangePicker subscriptions. They're useful if you want an opened DateRangePicker
panel to be closed when clicking outside of it.
-}
subscriptions : (State -> msg) -> State -> Sub msg
subscriptions tagger (State internal) =
    if internal.opened then
        BE.onMouseUp (Decode.succeed (update Close internal |> State |> tagger))

    else
        Sub.none
