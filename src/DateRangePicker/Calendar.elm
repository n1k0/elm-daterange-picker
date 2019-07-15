module DateRangePicker.Calendar exposing (fromPosix, view, weekdayNames)

import DateRangePicker.Helpers as Helpers exposing (sameDay)
import DateRangePicker.Range as Range
import DateRangePicker.Step as Step exposing (Step)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List.Extra as LE
import Time exposing (Posix, utc)
import Time.Extra as TE


type alias Config msg =
    { allowFuture : Bool
    , monthFormatter : Time.Month -> String
    , hover : Posix -> msg
    , hovered : Maybe Posix
    , noOp : msg
    , pick : Posix -> msg
    , prev : Maybe msg
    , next : Maybe msg
    , step : Step
    , target : Posix
    , today : Posix
    , weekdayFormatter : Time.Weekday -> String
    , weeksStartOn : Time.Weekday
    }


fromPosix : Time.Weekday -> Posix -> List (List Posix)
fromPosix weeksStartOn posix =
    let
        base =
            TE.startOfDay utc posix
    in
    List.range -7 42
        |> List.map (\v -> TE.addDays v base)
        |> LE.dropWhile (Time.toWeekday utc >> (/=) weeksStartOn)
        |> LE.groupsOf 7
        |> List.take 6


weekdayNames : (Time.Weekday -> String) -> Time.Weekday -> List String
weekdayNames weekdayFormatter weeksStartOn =
    let
        week =
            [ Time.Sun, Time.Mon, Time.Tue, Time.Wed, Time.Thu, Time.Fri, Time.Sat ]

        index =
            week |> LE.elemIndex weeksStartOn |> Maybe.withDefault 1
    in
    week
        |> LE.cycle (List.length week * 2)
        |> List.drop index
        |> List.take (List.length week)
        |> List.map weekdayFormatter


inRangePath : Maybe Posix -> Posix -> Posix -> Bool
inRangePath maybeHovered begin day =
    case maybeHovered of
        Just hovered ->
            Range.create begin hovered
                |> Range.between day

        Nothing ->
            False


dayCell : Config msg -> Posix -> Html msg
dayCell { allowFuture, hover, hovered, noOp, pick, step, target, today } day =
    let
        base =
            { active = False
            , start = False
            , end = False
            , inRange = False
            , inPath = False
            }

        { active, start, end, inRange, inPath } =
            case step of
                Step.Initial ->
                    base

                Step.Begin begin ->
                    { base
                        | active = sameDay utc begin day
                        , start = sameDay utc begin day
                        , inPath = inRangePath hovered begin day
                    }

                Step.Complete range ->
                    { base
                        | active = (range |> Range.beginsAt |> sameDay utc day) || (range |> Range.endsAt |> sameDay utc day)
                        , start = range |> Range.beginsAt |> sameDay utc day
                        , end = range |> Range.endsAt |> sameDay utc day
                        , inRange = range |> Range.between day
                    }

        disabled =
            not allowFuture && Time.posixToMillis day > Time.posixToMillis today
    in
    td
        ([ classList
            [ ( "EDRPCalendar__cell", True )
            , ( "EDRPCalendar__cell--today", sameDay utc day today )
            , ( "EDRPCalendar__cell--active", active )
            , ( "EDRPCalendar__cell--inRange", inRange || inPath )
            , ( "EDRPCalendar__cell--start", start )
            , ( "EDRPCalendar__cell--end", end )
            , ( "EDRPCalendar__cell--disabled", disabled )
            , ( "EDRPCalendar__cell--off", Time.toMonth utc target /= Time.toMonth utc day )
            ]
         , onMouseOver (hover day)
         , day |> Helpers.formatDate utc |> title
         ]
            ++ (if not disabled then
                    [ onClick (pick day) ]

                else
                    [ onClick noOp ]
               )
        )
        [ day |> Time.toDay utc |> String.fromInt |> text ]


navLink : String -> Maybe msg -> Html msg
navLink label maybeMsg =
    case maybeMsg of
        Just msg ->
            th [ class <| "EDRPCalendar__nav", onClick msg ] [ text label ]

        Nothing ->
            th [] []


view : Config msg -> Html msg
view ({ next, prev, target, weeksStartOn, weekdayFormatter, monthFormatter } as config) =
    div [ class "EDRPCalendar" ]
        [ table [ class "EDRPCalendar__table" ]
            [ thead []
                [ tr [ class "EDRPCalendar__head" ]
                    [ navLink "◄" prev
                    , th [ class "EDRPCalendar__month", colspan 5 ]
                        [ text (Helpers.shortMonth utc monthFormatter target) ]
                    , navLink "►" next
                    ]
                , weekdayNames weekdayFormatter weeksStartOn
                    |> List.map (\name -> th [] [ text name ])
                    |> tr []
                ]
            , target
                |> fromPosix weeksStartOn
                |> List.map (List.map (dayCell config) >> tr [])
                |> tbody []
            ]
        ]
