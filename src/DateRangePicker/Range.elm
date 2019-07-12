module DateRangePicker.Range exposing (Range, between, days, decode, encode, format, fromString, toString)

{-| Date range management.

@docs Range, between, days, decode, encode, format, fromString, toString

-}

import DateRangePicker.Helpers as Helpers
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time exposing (Posix)
import Time.Extra as TE


{-| A time range between two
[`Time.Posix`](https://package.elm-lang.org/packages/elm/time/latest/Time#Posix),
`begin` being inclusive and `end` exclusive.
-}
type alias Range =
    { begin : Posix
    , end : Posix
    }


{-| Checks if a [`Time.Posix`](https://package.elm-lang.org/packages/elm/time/latest/TimePosix)
is comprised within a [`Range`](#Range).
-}
between : Range -> Posix -> Bool
between { begin, end } day =
    Time.posixToMillis day >= Time.posixToMillis begin && Time.posixToMillis day < Time.posixToMillis end


{-| Computes the number of days in a [`Range`](#Range).
-}
days : Range -> Int
days { begin, end } =
    (Time.posixToMillis end - Time.posixToMillis begin) // 1000 // 86400


{-| Decodes a [`Range`](#Range) from JSON.
-}
decode : Decoder Range
decode =
    -- Note: date ranges received from the datepicker are expressed in UTC
    Decode.map2 Range
        (Decode.field "begin" Iso8601.decoder)
        (Decode.field "end" Iso8601.decoder)


{-| Encodes a [`Range`](#Range) to JSON.
-}
encode : Range -> Encode.Value
encode { begin, end } =
    Encode.object
        [ ( "begin", Iso8601.encode begin )
        , ( "end", end |> TE.endOfDay Time.utc |> Iso8601.encode )
        ]


{-| Formats a [`Range`](#Range) in simple fashion.
-}
format : Time.Zone -> Range -> String
format zone { begin, end } =
    if Helpers.sameDay zone begin end then
        "on " ++ Helpers.formatDate zone begin

    else
        "from " ++ Helpers.formatDate zone begin ++ " to " ++ Helpers.formatDate zone end


{-| Extract a [`Range`](#Range) from a String, where the two Posix timestamps are
encoded as UTC to Iso8601 format and joined with a `;` character.
-}
fromString : String -> Maybe Range
fromString str =
    case str |> String.split ";" |> List.map Iso8601.toTime of
        [ Ok begin, Ok end ] ->
            Just { begin = begin, end = end }

        _ ->
            Nothing


{-| Turns a [`Range`](#Range) into a String, where the two Posix timestamps are
encoded as UTC to Iso8601 format and joined with a `;` character.
-}
toString : Range -> String
toString { begin, end } =
    Iso8601.fromTime begin ++ ";" ++ Iso8601.fromTime end
