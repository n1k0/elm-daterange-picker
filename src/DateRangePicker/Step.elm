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


next : Posix -> Step -> Step
next picked step =
    case step of
        Begin begin ->
            if picked == begin then
                Complete (Range.create begin begin)

            else if Time.posixToMillis picked > Time.posixToMillis begin then
                Complete (Range.create begin picked)

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
