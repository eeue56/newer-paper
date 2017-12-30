module Page.Model exposing (..)

import Page.Game.Model
import Page.Welcome.Model


type Model
    = GameModel Page.Game.Model.Model
    | WelcomeModel Page.Welcome.Model.Model
