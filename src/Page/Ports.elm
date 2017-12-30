port module Page.Ports exposing (..)

import Json.Encode
import Json.Decode
import Json.Decode.FieldValue exposing (fieldValue)


type ElmToJs
    = StoreInLocalStorage Json.Decode.Value
    | ReadFromLocalStorage


type JsToElm
    = IncomingLocalStorage Json.Decode.Value
    | IgnoreableMessage


saveRoomName : String -> Cmd msg
saveRoomName roomName =
    Json.Encode.object [ ( "roomName", Json.Encode.string roomName ) ]
        |> StoreInLocalStorage
        |> encodeElmToJs
        |> fromElmToJs


encodeElmToJs : ElmToJs -> Json.Decode.Value
encodeElmToJs msg =
    case msg of
        ReadFromLocalStorage ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "ReadFromLocalStorage" ) ]

        StoreInLocalStorage obj ->
            Json.Encode.object
                [ ( "type", Json.Encode.string "StoreInLocalStorage" )
                , ( "value", obj )
                ]


port fromElmToJs : Json.Decode.Value -> Cmd msg


port fromJsToElmPort : (Json.Encode.Value -> msg) -> Sub msg


decodeIncomingLocalStorage : Json.Decode.Decoder JsToElm
decodeIncomingLocalStorage =
    Json.Decode.map2 (\_ -> IncomingLocalStorage)
        (Json.Decode.field "type" <| fieldValue "IncomingLocalStorage")
        (Json.Decode.field "value" <| Json.Decode.value)


decodeJsToElm : Json.Decode.Decoder JsToElm
decodeJsToElm =
    Json.Decode.oneOf
        [ decodeIncomingLocalStorage
        , Json.Decode.succeed IgnoreableMessage
        ]


fromJsToElm : Sub JsToElm
fromJsToElm =
    fromJsToElmPort
        (\value ->
            case Json.Decode.decodeValue decodeJsToElm value of
                Err e ->
                    IgnoreableMessage

                Ok v ->
                    v
        )
