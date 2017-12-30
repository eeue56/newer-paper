module Page.Results.Update exposing (..)

import Http
import Page.Results.Model exposing (..)


type Msg
    = ChangeRoomName String
    | CreateNewRoom
    | UpdateRoomInfo RoomInfo
    | FailedToCreateNewRoom Http.Error
    | JoinedRoom String


init : ( Model, Cmd Msg )
init =
    ( { roomName = "", roomInfo = Nothing, errors = [] }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeRoomName newName ->
            ( { model | roomName = newName }, Cmd.none )

        CreateNewRoom ->
            ( model, fetchCreateNewRoom )

        UpdateRoomInfo roomInfo ->
            ( { model | roomInfo = Just roomInfo, errors = [] }, Cmd.none )

        FailedToCreateNewRoom error ->
            let
                errors =
                    case error of
                        Http.NetworkError ->
                            [ "There was a problem connecting to the server" ]

                        Http.BadPayload message response ->
                            [ message ]

                        Http.Timeout ->
                            [ "Server took too long to reply" ]

                        _ ->
                            []
            in
                ( { model | roomInfo = Nothing, errors = "Failed to create room" :: errors }, Cmd.none )

        JoinedRoom _ ->
            ( model, Cmd.none )


createNewRoom : Http.Request RoomInfo
createNewRoom =
    Http.get "http://localhost:8888/create_room" decodeRoomInfo


fetchCreateNewRoom : Cmd Msg
fetchCreateNewRoom =
    Http.send
        (\res ->
            case res of
                Ok ok ->
                    UpdateRoomInfo ok

                Err e ->
                    FailedToCreateNewRoom e
        )
        createNewRoom
