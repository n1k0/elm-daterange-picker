module DateRangePickerTest exposing (suite)

import DateRangePicker
import DateRangePicker.Calendar as Calendar
import DateRangePicker.Helpers as Helpers
import DateRangePicker.Range as Range exposing (Range)
import Expect exposing (Expectation)
import Json.Decode as Decode
import Json.Encode as Encode
import Test exposing (..)
import Time exposing (Posix, utc)
import Time.Extra as TE


suite : Test
suite =
    describe "suite"
        [ calendarTests
        , helpersTests
        , rangeTests
        ]


calendarTests : Test
calendarTests =
    describe "Calendar"
        [ describe "fromPosix"
            [ TE.fromDateTuple utc ( 2019, Time.Jul, 1 )
                |> Calendar.fromPosix Time.utc Time.Mon
                |> toTestableCalendar
                |> Expect.equal
                    [ [ 24, 25, 26, 27, 28, 29, 30 ]
                    , [ 1, 2, 3, 4, 5, 6, 7 ]
                    , [ 8, 9, 10, 11, 12, 13, 14 ]
                    , [ 15, 16, 17, 18, 19, 20, 21 ]
                    , [ 22, 23, 24, 25, 26, 27, 28 ]
                    , [ 29, 30, 31, 1, 2, 3, 4 ]
                    ]
                |> asTest "should compute a calendar with weeks starting on Monday"
            , TE.fromDateTuple utc ( 2019, Time.Jul, 1 )
                |> Calendar.fromPosix Time.utc Time.Sun
                |> toTestableCalendar
                |> Expect.equal
                    [ [ 30, 1, 2, 3, 4, 5, 6 ]
                    , [ 7, 8, 9, 10, 11, 12, 13 ]
                    , [ 14, 15, 16, 17, 18, 19, 20 ]
                    , [ 21, 22, 23, 24, 25, 26, 27 ]
                    , [ 28, 29, 30, 31, 1, 2, 3 ]
                    , [ 4, 5, 6, 7, 8, 9, 10 ]
                    ]
                |> asTest "should compute a calendar with weeks starting on Sunday"
            ]
        ]


helpersTests : Test
helpersTests =
    describe "Helpers"
        [ describe "formatDate"
            [ TE.epoch
                |> Helpers.formatDate Time.utc
                |> Expect.equal "1970-01-01"
                |> asTest "should format a date from a posix"
            ]
        , describe "formatDateTime"
            [ TE.epoch
                |> Helpers.formatDateTime Time.utc
                |> Expect.equal "1970-01-01 00:00"
                |> asTest "should format a datetime from a posix"
            ]
        , describe "sameDay"
            [ TE.epoch
                |> Helpers.sameDay utc (TE.addHours 23 TE.epoch)
                |> Expect.equal True
                |> asTest "should check if two posix are within the same day"
            , TE.epoch
                |> Helpers.sameDay utc (TE.addHours 25 TE.epoch)
                |> Expect.equal False
                |> asTest "should check if two posix are not within the same day"
            ]
        , describe "startOfNextMonth"
            [ TE.fromDateTuple utc ( 2018, Time.Aug, 15 )
                |> Helpers.startOfNextMonth utc
                |> Helpers.formatDateTime utc
                |> Expect.equal "2018-09-01 00:00"
                |> asTest "should resolve the start of next month"
            ]
        , describe "startOfPreviousMonth"
            [ TE.fromDateTuple utc ( 2018, Time.Aug, 15 )
                |> Helpers.startOfPreviousMonth utc
                |> Helpers.formatDateTime utc
                |> Expect.equal "2018-07-01 00:00"
                |> asTest "should resolve the start of previous month"
            ]
        , describe "weekdayNames"
            [ Calendar.weekdayNames Helpers.weekdayToString Time.Mon
                |> Expect.equal [ "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" ]
                |> asTest "should return week day names sarting from Monday"
            , Calendar.weekdayNames Helpers.weekdayToString Time.Sun
                |> Expect.equal [ "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa" ]
                |> asTest "should return week day names sarting from Sunday"
            , Calendar.weekdayNames Helpers.weekdayToString Time.Wed
                |> Expect.equal [ "We", "Th", "Fr", "Sa", "Su", "Mo", "Tu" ]
                |> asTest "should return week day names sarting from Wednesday"
            ]
        ]


rangeTests : Test
rangeTests =
    describe "Range"
        [ describe "between"
            [ sampleRange
                |> Range.between (TE.addDays 1 begin)
                |> Expect.equal True
                |> asTest "should test if a datetime is comprised between a range"
            , sampleRange
                |> Range.between (TE.addDays 100 begin)
                |> Expect.equal False
                |> asTest "should test if a datetime exceeds a range"
            , sampleRange
                |> Range.between (TE.addDays -100 begin)
                |> Expect.equal False
                |> asTest "should test if a datetime is before a range"
            ]
        , describe "create"
            [ Range.create utc begin end
                |> Range.toTuple
                |> Expect.equal ( begin, end )
                |> asTest "should create a Range"
            , Range.create utc end begin
                |> Range.toTuple
                |> Expect.equal ( begin, end )
                |> asTest "should ensure consistency"
            ]
        , describe "decode"
            [ sampleJsonRange
                |> Decode.decodeString Range.decode
                |> Expect.equal (Ok sampleRange)
                |> asTest "should decode a JSON date range"
            ]
        , describe "encode"
            [ sampleRange
                |> Range.encode
                |> Encode.encode 0
                |> Expect.equal sampleJsonRange
                |> asTest "should encode a Range"
            ]
        , describe "format"
            [ Range.create utc begin begin
                |> Range.format utc
                |> Expect.equal "on 2018-01-01"
                |> asTest "should format a single day date range"
            , sampleRange
                |> Range.format utc
                |> Expect.equal "from 2018-01-01 to 2018-01-08"
                |> asTest "should format a multiple days period date range"
            ]
        , describe "fromString"
            [ "2018-01-01T00:00:00.000Z;2018-01-08T23:59:59.999Z"
                |> Range.fromString
                |> Expect.equal (Just sampleRange)
                |> asTest "should import a range from a String"
            ]
        , describe "toString"
            [ sampleRange
                |> Range.toString
                |> Expect.equal "2018-01-01T00:00:00.000Z;2018-01-08T23:59:59.999Z"
                |> asTest "should transform a range to a String"
            ]
        , describe "days"
            [ Range.days sampleRange
                |> Expect.equal 7
                |> asTest "should compute the number of days in a range"
            ]
        ]


asTest : String -> Expectation -> Test
asTest label =
    always >> test label


begin : Posix
begin =
    TE.fromDateTuple utc ( 2018, Time.Jan, 1 )


end : Posix
end =
    begin |> TE.addDays 7 |> TE.endOfDay utc


sampleRange : Range
sampleRange =
    Range.create utc begin end


sampleJsonRange : String
sampleJsonRange =
    "{\"begin\":\"2018-01-01T00:00:00.000Z\",\"end\":\"2018-01-08T23:59:59.999Z\"}"


toTestableCalendar : List (List Posix) -> List (List Int)
toTestableCalendar =
    List.map (List.map (Time.toDay utc))
