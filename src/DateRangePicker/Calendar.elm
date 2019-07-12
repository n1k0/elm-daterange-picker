module DateRangePicker.Calendar exposing (fromPosix, view, weekdayNames)

import DateRangePicker.Helpers as Helpers
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


dayCell : Config msg -> Posix -> Html msg
dayCell { allowFuture, pick, step, target, today } day =
    let
        base =
            { active = False, start = False, end = False, inRange = False }

        { active, start, end, inRange } =
            case step of
                Step.Initial ->
                    base

                Step.Begin begin ->
                    { base
                        | active = Helpers.sameDay utc begin day
                        , start = Helpers.sameDay utc begin day
                    }

                Step.Complete range ->
                    { base
                        | active = Helpers.sameDay utc range.begin day || Helpers.sameDay utc range.end day
                        , start = Helpers.sameDay utc range.begin day
                        , end = Helpers.sameDay utc range.end day
                        , inRange = Range.between range day
                    }

        disabled =
            not allowFuture && Time.posixToMillis day > Time.posixToMillis today
    in
    td
        ([ classList
            [ ( "EDRPCalendar__cell", not disabled && Time.toMonth utc target == Time.toMonth utc day )
            , ( "today", Helpers.sameDay utc day today )
            , ( "EDRPCalendar__cell--active", active )
            , ( "EDRPCalendar__cell--inRange", inRange )
            , ( "EDRPCalendar__cell--start", start )
            , ( "EDRPCalendar__cell--end", end )
            , ( "EDRPCalendar__cell ends off disabled", disabled )
            , ( "EDRPCalendar__cell EDRPCalendar__cell--off", Time.toMonth utc target /= Time.toMonth utc day )
            ]
         , day |> Helpers.formatDate utc |> title
         ]
            ++ (if not disabled then
                    [ onClick (pick day) ]

                else
                    []
               )
        )
        [ day |> Time.toDay utc |> String.fromInt |> text ]


navLink : String -> Maybe msg -> Html msg
navLink label maybeMsg =
    case maybeMsg of
        Just msg ->
            th [ class <| label ++ " available", onClick msg ] [ span [] [] ]

        Nothing ->
            th [] [ span [] [] ]


view : Config msg -> Html msg
view ({ next, prev, target, weeksStartOn, weekdayFormatter, monthFormatter } as config) =
    div [ class "EDRPCalendar" ]
        [ table [ class "EDRPCalendar__table" ]
            [ thead []
                [ tr []
                    [ navLink "EDRPCalendar__nav EDRPCalendar__nav--prev" prev
                    , th [ class "month", colspan 5 ]
                        [ text (Helpers.shortMonth utc monthFormatter target) ]
                    , navLink "EDRPCalendar__nav EDRPCalendar__nav--next" next
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
