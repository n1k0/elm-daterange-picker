module DateRangePicker.Calendar exposing (Translations, fromPosix, view, weekdayNames)

import DateRangePicker.Helpers as Helpers exposing (sameDay)
import DateRangePicker.Range as Range
import DateRangePicker.Step as Step exposing (Step)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List.Extra as LE
import Time exposing (Posix)
import Time.Extra as TE


{-| ActionButtons labels configuration:

  - `close`: Button, which will close daterange-picker
  - `clear`: Button, which will clear input string
  - `apply`: Button, which will set new daterange
  - `pickStart`: Hint at the bottom of calendar, before user pick the first date
  - `pickEnd`: Hint at the bottom of calendar, after user pick the first date

-}
type alias Translations =
    { close : String
    , clear : String
    , apply : String
    , pickStart : String
    , pickEnd : String
    }


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
    , translations : Translations
    , weekdayFormatter : Time.Weekday -> String
    , weeksStartOn : Time.Weekday
    , zone : Time.Zone
    }


fromPosix : Time.Zone -> Time.Weekday -> Posix -> List (List Posix)
fromPosix zone weeksStartOn posix =
    let
        base =
            TE.startOfDay zone posix
    in
    List.range -7 42
        |> List.map (\v -> TE.addDaysZ v zone base)
        |> LE.dropWhile (Time.toWeekday zone >> (/=) weeksStartOn)
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


inRangePath : Time.Zone -> Maybe Posix -> Posix -> Posix -> Bool
inRangePath zone maybeHovered begin day =
    case maybeHovered of
        Just hovered ->
            Range.create zone begin hovered
                |> Range.between day

        Nothing ->
            False


dayCell : Config msg -> Posix -> Html msg
dayCell { allowFuture, hover, hovered, noOp, pick, step, target, today, zone } day =
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
                        | active = sameDay zone begin day
                        , start = sameDay zone begin day
                        , inPath = inRangePath zone hovered begin day
                    }

                Step.Complete range ->
                    { base
                        | active = (range |> Range.beginsAt |> sameDay zone day) || (range |> Range.endsAt |> sameDay zone day)
                        , start = range |> Range.beginsAt |> sameDay zone day
                        , end = range |> Range.endsAt |> sameDay zone day
                        , inRange = range |> Range.between day
                    }

        disabled =
            not allowFuture && Time.posixToMillis day > Time.posixToMillis today
    in
    td
        ([ classList
            [ ( "EDRPCalendar__cell", True )
            , ( "EDRPCalendar__cell--today", sameDay zone day today )
            , ( "EDRPCalendar__cell--active", active )
            , ( "EDRPCalendar__cell--inRange", inRange || inPath )
            , ( "EDRPCalendar__cell--start", start )
            , ( "EDRPCalendar__cell--end", end )
            , ( "EDRPCalendar__cell--disabled", disabled )
            , ( "EDRPCalendar__cell--off", Time.toMonth zone target /= Time.toMonth zone day )
            ]
         , onMouseOver (hover day)
         , day |> Helpers.formatDate zone |> title
         ]
            ++ (if not disabled then
                    [ onClick (pick day) ]

                else
                    [ onClick noOp ]
               )
        )
        [ day |> Time.toDay zone |> String.fromInt |> text ]


navLink : String -> Maybe msg -> Html msg
navLink label maybeMsg =
    case maybeMsg of
        Just msg ->
            th [ class <| "EDRPCalendar__nav", onClick msg ] [ text label ]

        Nothing ->
            th [] []


view : Config msg -> Html msg
view ({ next, prev, target, weeksStartOn, weekdayFormatter, monthFormatter, zone } as config) =
    div [ class "EDRPCalendar" ]
        [ table [ class "EDRPCalendar__table" ]
            [ thead []
                [ tr [ class "EDRPCalendar__head" ]
                    [ navLink "◄" prev
                    , th [ class "EDRPCalendar__month", colspan 5 ]
                        [ text (Helpers.shortMonth zone monthFormatter target) ]
                    , navLink "►" next
                    ]
                , weekdayNames weekdayFormatter weeksStartOn
                    |> List.map (\name -> th [] [ text name ])
                    |> tr []
                ]
            , target
                |> fromPosix zone weeksStartOn
                |> List.map (List.map (dayCell config) >> tr [])
                |> tbody []
            ]
        ]
