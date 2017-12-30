module Page.Main exposing (..)

import Page.Update exposing (..)
import Page.View exposing (..)
import Page.Model exposing (..)
import Html


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
