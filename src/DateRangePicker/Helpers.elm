module DateRangePicker.Helpers exposing
    ( formatDate
    , formatDateTime
    , formatTime
    , monthToString
    , sameDay
    , shortMonth
    , startOfNextMonth
    , startOfPreviousMonth
    , weekdayToString
    )

import Time exposing (Posix)
import Time.Extra as TE


formatDate : Time.Zone -> Posix -> String
formatDate zone posix =
    String.join "-"
        [ posix |> Time.toYear zone |> String.fromInt
        , posix |> Time.toMonth zone |> TE.monthToInt |> int00
        , posix |> Time.toDay zone |> int00
        ]


formatDateTime : Time.Zone -> Posix -> String
formatDateTime zone posix =
    formatDate zone posix ++ " " ++ formatTime zone posix


formatTime : Time.Zone -> Posix -> String
formatTime zone posix =
    String.join ":"
        [ posix |> Time.toHour zone |> int00
        , posix |> Time.toMinute zone |> int00
        ]


int00 : Int -> String
int00 =
    String.fromInt >> String.padLeft 2 '0'


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"


sameDay : Time.Zone -> Posix -> Posix -> Bool
sameDay zone a b =
    TE.toDateTuple zone a == TE.toDateTuple zone b


shortMonth : Time.Zone -> (Time.Month -> String) -> Posix -> String
shortMonth zone monthFormatter day =
    monthFormatter (Time.toMonth zone day) ++ " " ++ String.fromInt (Time.toYear zone day)


startOfNextMonth : Time.Zone -> Posix -> Posix
startOfNextMonth zone =
    TE.endOfMonth zone >> TE.addMillis 1


startOfPreviousMonth : Time.Zone -> Posix -> Posix
startOfPreviousMonth zone =
    TE.startOfMonth zone >> TE.addMillis -1 >> TE.startOfMonth zone


weekdayToString : Time.Weekday -> String
weekdayToString day =
    case day of
        Time.Sun ->
            "Su"

        Time.Mon ->
            "Mo"

        Time.Tue ->
            "Tu"

        Time.Wed ->
            "We"

        Time.Thu ->
            "Th"

        Time.Fri ->
            "Fr"

        Time.Sat ->
            "Sa"
