module DateRangePicker exposing
    ( Config, defaultConfig, configure
    , State, init, now, nowTask, getRange, setRange, setToday, disable, isDisabled, open, isOpened
    , view
    , subscriptions
    )

{-| A configurable date range picker widget.


# Configuration

@docs Config, defaultConfig, configure


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
import Time exposing (Posix, utc)
import Time.Extra as TE


{-| DateRangePicker configuration:

  - `allowFuture`: Allow picking a range in the future
  - `applyRangeImmediately`: Apply predefined range immediately when clicked
  - `weekdayFormatter`: How to format a [`Time.Weekday`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months)
  - `monthFormatter`: How to format a [`Time.Month`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months)
  - `noRangeCaption`: The String to render when no range is set
  - `predefinedRanges`: Generates custom predefined ranges.
  - `sticky`: Make the picker always opened
  - `weeksStartOn`: The [`Time.Weekday`](https://package.elm-lang.org/packages/elm/time/latest/Time#weeks-and-months) weeks start on (eg. `Time.Mon` or `Time.Sun`)

-}
type alias Config =
    { allowFuture : Bool
    , applyRangeImmediately : Bool
    , weekdayFormatter : Time.Weekday -> String
    , monthFormatter : Time.Month -> String
    , noRangeCaption : String
    , predefinedRanges : Posix -> List ( String, Range )
    , sticky : Bool
    , weeksStartOn : Time.Weekday
    }


{-| A Config featuring the following default values:

  - `allowFuture`: `True`
  - `applyRangeImmediately`: `True`
  - `weekdayFormatter`: Converts weekday names to their 2 chars English equivalent: `Mo`, `Tu`, etc.
  - `monthFormatter`: Converts month names to their 3 chars English equivalent: `Jan`, `Feb`, etc.
  - `noRangeCaption`: `"N/A"`
  - `predefinedRanges`: `"Today"`, `"Yesterday"`, `"Last 7 days"`, `"Last 30 days"`, `"This month"` and `"Last month"`
  - `sticky`: `False`
  - `weeksStartOn`: `Time.Mon` (weeks start on Monday)

-}
defaultConfig : Config
defaultConfig =
    { allowFuture = True
    , applyRangeImmediately = True
    , weekdayFormatter = Helpers.weekdayToString
    , monthFormatter = Helpers.monthToString
    , noRangeCaption = "N/A"
    , predefinedRanges = defaultPredefinedRanges
    , sticky = False
    , weeksStartOn = Time.Mon
    }


{-| Helper to selectively alter [`defaultConfig`](#defaultConfig):

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


{-| Initializes a State from a [`Config`](#Config) and a preselected
[`Range`](./DateRangePicker-Range#Range).

Note: this will position the calendar at Unix Epoch (Jan, 1st 1970 UTC). To
position it to today's date, look at [`now`](#now)

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


{-| A command for positioning the DateRangePicker at today's date.

    init : () -> ( Model, Cmd Msg )
    init _ =
        let
            picker =
                Picker.init Nothing
        in
        ( picker, Picker.now picker PickerChanged )

-}
now : (State -> msg) -> State -> Cmd msg
now toMsg (State internal) =
    nowTask internal.config internal.current
        |> Task.perform toMsg


{-| A Task for initializing a State with a [`Range`](./DateRangePicker-Range#Range)
and today's date.
-}
nowTask : Config -> Maybe Range -> Task Never State
nowTask config selected =
    Time.now
        |> Task.andThen (\today -> init config selected |> setToday today |> Task.succeed)


{-| Get the current [`Range`](./DateRangePicker-Range#Range) of the DateRangePicker, if any.
-}
getRange : State -> Maybe Range
getRange (State internal) =
    internal.current


{-| Assign a selected [`Range`](./DateRangePicker-Range#Range) to the DateRangePicker.

    import DateRangePicker.Range as Range

    state |> setRange (Range.create begin end)

-}
setRange : Maybe Range -> State -> State
setRange dateRange (State internal) =
    State { internal | current = dateRange, step = Step.fromMaybe dateRange }


{-| Sets current DateRangePicker date.
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


{-| Checks if the DateRangePicker is currently disabled.
-}
isDisabled : State -> Bool
isDisabled (State internal) =
    internal.disabled


{-| Checks if the DateRangePicker is currently opened.

Note: always returns `True` when the `sticky` option is enabled

-}
isOpened : State -> Bool
isOpened (State internal) =
    internal.config.sticky || internal.opened


{-| Disable or enable a DateRangePicker.
-}
disable : Bool -> State -> State
disable disabled (State internal) =
    State { internal | disabled = disabled }


{-| Open or close a DateRangePicker.

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
getCalendars config maybeRange today =
    case ( config.allowFuture, maybeRange ) of
        ( True, Just range ) ->
            ( range |> Range.beginsAt |> TE.startOfMonth utc
            , range |> Range.beginsAt |> Helpers.startOfNextMonth utc
            )

        ( False, Just range ) ->
            ( range |> Range.endsAt |> Helpers.startOfPreviousMonth utc
            , range |> Range.endsAt |> TE.startOfMonth utc
            )

        ( _, Nothing ) ->
            ( today |> Helpers.startOfPreviousMonth utc
            , today |> TE.startOfMonth utc
            )


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
                , rightCal = Helpers.startOfNextMonth utc rightCal
            }

        NoOp ->
            internal

        Open ->
            { internal | opened = True }

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
handleEvent toMsg msg =
    update msg >> State >> toMsg


defaultPredefinedRanges : Posix -> List ( String, Range )
defaultPredefinedRanges today =
    let
        daysBefore n posix =
            posix |> TE.addDays -n |> TE.startOfDay utc
    in
    [ ( "Today"
      , Range.create (TE.startOfDay utc today) (TE.endOfDay utc today)
      )
    , ( "Yesterday"
      , Range.create (today |> daysBefore 1 |> TE.startOfDay utc) (today |> daysBefore 1 |> TE.endOfDay utc)
      )
    , ( "Last 7 days"
      , Range.create (today |> daysBefore 7) (today |> TE.startOfDay utc |> TE.addMillis -1)
      )
    , ( "Last 30 days"
      , Range.create (today |> daysBefore 30) (today |> TE.startOfDay utc |> TE.addMillis -1)
      )
    , ( "This month"
      , Range.create (today |> TE.startOfMonth utc) today
      )
    , ( "Last month"
      , Range.create (today |> Helpers.startOfPreviousMonth utc) (today |> TE.startOfMonth utc |> TE.addMillis -1)
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
            |> internal.config.predefinedRanges
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
            , today = internal.today
            , weekdayFormatter = internal.config.weekdayFormatter
            , weeksStartOn = internal.config.weeksStartOn
            }

        allowNext =
            internal.config.allowFuture
                || (internal.rightCal |> TE.startOfMonth utc |> Time.posixToMillis)
                < (internal.today |> TE.startOfMonth utc |> Time.posixToMillis)

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
        , div [ class "EDRPFoot" ]
            [ span []
                [ case internal.step of
                    Step.Initial ->
                        text "Hint: pick a start date"

                    Step.Begin _ ->
                        text "Hint: pick an end date"

                    Step.Complete range ->
                        range |> Range.format utc |> text
                ]
            , div [ class "EDRPFoot__actions" ]
                [ if not internal.config.sticky then
                    button
                        [ class "EDRP__button"
                        , type_ "button"
                        , onClick <| handleEvent toMsg Close internal
                        ]
                        [ text "Close" ]

                  else
                    text ""
                , button
                    [ class "EDRP__button"
                    , type_ "button"
                    , HA.disabled (internal.step == Step.Initial)
                    , onClick <| handleEvent toMsg Clear internal
                    ]
                    [ text "Clear" ]
                , button
                    [ class "EDRP__button EDRP__button--primary"
                    , type_ "button"
                    , onClick <| handleEvent toMsg (Apply (Step.toMaybe internal.step)) internal
                    ]
                    [ text "Apply" ]
                ]
            ]
        ]


{-| The main DateRangePicker view.

The first argument...

-}
view : (State -> msg) -> State -> Html msg
view toMsg (State internal) =
    div [ class "EDRP" ]
        [ input
            [ type_ "text"
            , HA.disabled internal.disabled
            , internal.current
                |> Maybe.map (Range.format utc)
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


{-| DateRangePicker subscriptions. They're useful if you want an opened DateRangePicker
panel to be closed when clicking outside of it.
-}
subscriptions : (State -> msg) -> State -> Sub msg
subscriptions toMsg (State internal) =
    if internal.opened && not internal.config.sticky then
        BE.onMouseUp (Decode.succeed (handleEvent toMsg Close internal))

    else
        Sub.none
