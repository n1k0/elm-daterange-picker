module TestSuite exposing (suite)

import DateRangePicker as DRP
import Expect exposing (Expectation)
import Test exposing (..)
import Time exposing (Posix)
import Time.Extra as TE
import TimeZone


asTest : String -> Expectation -> Test
asTest label =
    always >> test label


config : DRP.Config
config =
    { zone = TimeZone.europe__paris ()
    , weeksStartOnMonday = False
    }


toTestableCalendar : List (List Posix) -> List (List Int)
toTestableCalendar =
    List.map (List.map (Time.toDay config.zone))


suite : Test
suite =
    describe "calendar"
        [ TE.fromDateTuple config.zone ( 2019, Time.Jul, 15 )
            |> DRP.calendar config
            |> toTestableCalendar
            |> Expect.equal
                [ [ 30, 1, 2, 3, 4, 5, 6 ]
                , [ 7, 8, 9, 10, 11, 12, 13 ]
                , [ 14, 15, 16, 17, 18, 19, 20 ]
                , [ 21, 22, 23, 24, 25, 26, 27 ]
                , [ 28, 29, 30, 31, 1, 2, 3 ]
                , [ 4, 5, 6, 7, 8, 9, 10 ]
                ]
            |> asTest "should build a calendar with weeks starting on Sunday"
        , TE.fromDateTuple config.zone ( 2019, Time.Jul, 15 )
            |> DRP.calendar { config | weeksStartOnMonday = True }
            |> toTestableCalendar
            |> Expect.equal
                [ [ 1, 2, 3, 4, 5, 6, 7 ]
                , [ 8, 9, 10, 11, 12, 13, 14 ]
                , [ 15, 16, 17, 18, 19, 20, 21 ]
                , [ 22, 23, 24, 25, 26, 27, 28 ]
                , [ 29, 30, 31, 1, 2, 3, 4 ]
                , [ 5, 6, 7, 8, 9, 10, 11 ]
                ]
            |> asTest "should build a calendar with weeks starting on Monday"
        ]
