module Page.Welcome.Main exposing (..)

import Html exposing (Html)
import Page.Welcome.Model exposing (..)
import Page.Welcome.Update exposing (..)
import Page.Welcome.View exposing (..)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
