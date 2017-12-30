module Page.View exposing (..)

import Page.Game.View
import Page.Welcome.View
import Page.Update exposing (..)
import Page.Model exposing (..)
import Html exposing (Html)


view : Model -> Html Msg
view middleModel =
    case middleModel of
        WelcomeModel model ->
            Page.Welcome.View.view model
                |> Html.map WelcomeUpdate

        GameModel model ->
            Page.Game.View.view model
                |> Html.map GameUpdate
