module Page.Welcome.Model exposing (..)

import Json.Decode


type alias Model =
    { roomName : String, roomInfo : Maybe RoomInfo, errors : List String }


type alias RoomInfo =
    { roomName : String }


decodeRoomInfo : Json.Decode.Decoder RoomInfo
decodeRoomInfo =
    Json.Decode.map RoomInfo
        (Json.Decode.field "room_name" Json.Decode.string)
