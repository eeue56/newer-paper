module Page.Game.Main exposing (..)

import Html
import Page.Game.Model exposing (Model)
import Page.Game.View exposing (view)
import Page.Game.Update exposing (..)


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
