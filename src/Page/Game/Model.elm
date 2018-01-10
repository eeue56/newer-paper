module Page.Game.Model exposing (..)

import Data.QuestionSet exposing (QuestionSet)
import Json.Decode
import Json.Encode


type alias Model =
    { set : QuestionSet
    , currentPlayerCount : Int
    , questionAmount : Int
    , questionIndex : Int
    , roomName : String
    , isStarted : Bool
    , playerNames : List String
    }


defaultModel : Model
defaultModel =
    { set =
        { answers =
            [ "a", "b", "c", "d" ]
        , question = "Which letter comes first?"
        }
    , currentPlayerCount = 0
    , questionIndex = 0
    , questionAmount = 0
    , roomName = ""
    , isStarted = False
    , playerNames = []
    }


encodeModel : Model -> Json.Encode.Value
encodeModel model =
    Json.Encode.object [ ( "roomName", Json.Encode.string model.roomName ) ]


decodeRoomname : Json.Decode.Decoder String
decodeRoomname =
    Json.Decode.field "roomName" Json.Decode.string
