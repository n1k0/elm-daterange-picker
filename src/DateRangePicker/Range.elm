module DateRangePicker.Range exposing
    ( Range, create, beginsAt, endsAt
    , between, days, format
    , decode, encode, fromString, toString, toTuple
    )

{-| Date range management.


# Range

@docs Range, create, beginsAt, endsAt


# Helpers

@docs between, days, format


# Conversion

@docs decode, encode, fromString, toString, toTuple

-}

import DateRangePicker.Helpers as Helpers
import Iso8601
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time exposing (Posix, posixToMillis)
import Time.Extra as TE


{-| A time range between two
[`Time.Posix`](https://package.elm-lang.org/packages/elm/time/latest/Time#Posix).
-}
type Range
    = Range InternalRange


type alias InternalRange =
    { begin : Posix
    , end : Posix
    }


{-| Creates a [`Range`](#Range).
-}
create : Posix -> Posix -> Range
create begin end =
    case TE.compare begin end of
        GT ->
            Range { begin = end, end = begin }

        _ ->
            Range { begin = begin, end = end }


{-| Retrieves the Posix the [`Range`](#Range) begins at.
-}
beginsAt : Range -> Posix
beginsAt (Range { begin }) =
    begin


{-| Retrieves the Posix the [`Range`](#Range) ends at.
-}
endsAt : Range -> Posix
endsAt (Range { end }) =
    end


{-| Checks if a [`Time.Posix`](https://package.elm-lang.org/packages/elm/time/latest/TimePosix)
is comprised within a [`Range`](#Range).
-}
between : Range -> Posix -> Bool
between (Range { begin, end }) day =
    posixToMillis day >= posixToMillis begin && posixToMillis day < posixToMillis end


{-| Computes the number of days in a [`Range`](#Range), floored.
-}
days : Range -> Int
days (Range { begin, end }) =
    (posixToMillis end - posixToMillis begin) // 1000 // 86400


{-| Decodes a [`Range`](#Range) from JSON.
-}
decode : Decoder Range
decode =
    -- Note: date ranges received from the datepicker are expressed in UTC
    Decode.map2 InternalRange
        (Decode.field "begin" Iso8601.decoder)
        (Decode.field "end" Iso8601.decoder)
        |> Decode.andThen (Range >> Decode.succeed)


{-| Encodes a [`Range`](#Range) to JSON.
-}
encode : Range -> Encode.Value
encode (Range { begin, end }) =
    Encode.object
        [ ( "begin", Iso8601.encode begin )
        , ( "end", end |> TE.endOfDay Time.utc |> Iso8601.encode )
        ]


{-| Formats a [`Range`](#Range) in simple fashion.
-}
format : Time.Zone -> Range -> String
format zone (Range { begin, end }) =
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
            Just (Range { begin = begin, end = end })

        _ ->
            Nothing


{-| Turns a [`Range`](#Range) into a String, where the two Posix timestamps are
encoded as UTC to Iso8601 format and joined with a `;` character.
-}
toString : Range -> String
toString (Range { begin, end }) =
    Iso8601.fromTime begin ++ ";" ++ Iso8601.fromTime end


{-| Converts a [`Range`](#Range) into a Tuple.
-}
toTuple : Range -> ( Posix, Posix )
toTuple (Range { begin, end }) =
    ( begin, end )
