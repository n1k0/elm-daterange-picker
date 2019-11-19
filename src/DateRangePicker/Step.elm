module DateRangePicker.Step exposing (Step(..), fromMaybe, next, toMaybe)

import DateRangePicker.Range as Range exposing (Range)
import Time exposing (Posix)


type Step
    = Initial
    | Begin Posix
    | Complete Range


fromMaybe : Maybe Range -> Step
fromMaybe =
    Maybe.map Complete >> Maybe.withDefault Initial


next : Time.Zone -> Posix -> Step -> Step
next zone picked step =
    case step of
        Begin begin ->
            if picked == begin then
                Complete (Range.create zone begin begin)

            else if Time.posixToMillis picked > Time.posixToMillis begin then
                Complete (Range.create zone begin picked)

            else
                Begin picked

        Complete _ ->
            Begin picked

        Initial ->
            Begin picked


toMaybe : Step -> Maybe Range
toMaybe step =
    case step of
        Complete dateRange ->
            Just dateRange

        _ ->
            Nothing
