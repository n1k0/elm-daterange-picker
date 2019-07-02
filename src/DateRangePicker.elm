module DateRangePicker exposing (Config, DateRange, calendar)

import List.Extra as LE
import Time exposing (Posix)
import Time.Extra as TE


type alias Config =
    { zone : Time.Zone
    , weeksStartOnMonday : Bool
    }


type alias DateRange =
    { zone : Time.Zone
    , start : Posix
    , days : Int
    }


calendar : Config -> Posix -> List (List Posix)
calendar ({ weeksStartOnMonday, zone } as config) target =
    let
        startOfMonth =
            TE.startOfMonth zone target
    in
    List.range (dayOffset config target) 42
        |> List.map (\next -> TE.addDaysZ next zone startOfMonth)
        |> LE.groupsOf 7
        |> List.take 6


dayOffset : Config -> Posix -> Int
dayOffset { weeksStartOnMonday, zone } =
    Time.toWeekday zone
        >> TE.weekdayToInt
        >> (\dayIndex ->
                if weeksStartOnMonday then
                    -dayIndex + 1

                else
                    -dayIndex
           )
