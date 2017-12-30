module Page.Results.Main exposing (..)

import Html exposing (Html)
import Page.Results.Model exposing (..)
import Page.Results.Update exposing (..)
import Page.Results.View exposing (..)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
