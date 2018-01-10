module Page.Game.Update exposing (..)

import Json.Decode
import Json.Decode.FieldValue exposing (fieldValue)
import Json.Encode
import WebSocket
import Task
import Data.QuestionSet exposing (QuestionSet)
import Page.Game.Model exposing (..)


type Msg
    = Noop
    | ParseWebsocketMessage String
    | AnswerGiven String
    | NoRoomFound


init : ( Model, Cmd Msg )
init =
    initWithRoomName ""


initWithRoomName : String -> ( Model, Cmd Msg )
initWithRoomName roomName =
    ( { defaultModel | roomName = roomName }
    , send (JoinRoom roomName)
    )


send : Request -> Cmd msg
send request =
    encodeRequest request
        |> Json.Encode.encode 0
        |> WebSocket.send "ws://localhost:8888/websocket"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Noop ->
            ( model, Cmd.none )

        ParseWebsocketMessage string ->
            case Json.Decode.decodeString decodeResponse string of
                Err e ->
                    ( model, Cmd.none )

                Ok response ->
                    case response of
                        CurrentQuestion set ->
                            ( { model | set = set }, Cmd.none )

                        Opened ->
                            ( model, send GetCurrentQuestion )

                        NoSuchRoom ->
                            ( model, Task.succeed NoRoomFound |> Task.perform (\msg -> msg) )

                        CurrentPlayerCount count ->
                            ( { model | currentPlayerCount = count }, Cmd.none )

                        CurrentPlayerNames names ->
                            ( { model | playerNames = names }, Cmd.none )

                        CurrentQuestionInfo amount index ->
                            ( { model | questionAmount = amount, questionIndex = index }, Cmd.none )

        AnswerGiven answer ->
            ( model, send (SetAnswer answer) )

        NoRoomFound ->
            ( model, Cmd.none )


decodeResponse : Json.Decode.Decoder Response
decodeResponse =
    Json.Decode.oneOf
        [ Json.Decode.map CurrentQuestion decodeCurrentQuestion
        , decodeOpened
        , decodeNoSuchRoom
        , Json.Decode.map CurrentPlayerCount decodeCurrentPlayerCount
        , Json.Decode.map CurrentPlayerNames decodeCurrentPlayerNames
        , decodeCurrentQuestionInfo
        ]


decodeCurrentQuestion : Json.Decode.Decoder QuestionSet
decodeCurrentQuestion =
    Json.Decode.map3 ((\_ -> QuestionSet))
        (Json.Decode.field "response" <| fieldValue "CURRENT_QUESTION")
        (Json.Decode.at [ "props", "question" ] Json.Decode.string)
        (Json.Decode.at [ "props", "answers" ] <| Json.Decode.list Json.Decode.string)


decodeOpened : Json.Decode.Decoder Response
decodeOpened =
    Json.Decode.map (\_ -> Opened)
        (Json.Decode.field "response" <| fieldValue "OPENED")


decodeNoSuchRoom : Json.Decode.Decoder Response
decodeNoSuchRoom =
    Json.Decode.map (\_ -> NoSuchRoom)
        (Json.Decode.field "response" <| fieldValue "NO_SUCH_ROOM")


decodeCurrentPlayerCount : Json.Decode.Decoder Int
decodeCurrentPlayerCount =
    Json.Decode.map2 (\_ n -> n)
        (Json.Decode.field "response" <| fieldValue "CURRENT_PLAYER_COUNT")
        (Json.Decode.at [ "props", "count" ] Json.Decode.int)


decodeCurrentPlayerNames : Json.Decode.Decoder (List String)
decodeCurrentPlayerNames =
    Json.Decode.map2 (\_ n -> n)
        (Json.Decode.field "response" <| fieldValue "CURRENT_PLAYER_NAMES")
        (Json.Decode.at [ "props", "names" ] <| Json.Decode.list Json.Decode.string)


decodeCurrentQuestionInfo : Json.Decode.Decoder Response
decodeCurrentQuestionInfo =
    Json.Decode.map3 (\_ -> CurrentQuestionInfo)
        (Json.Decode.field "response" <| fieldValue "QUESTIONS_INFO")
        (Json.Decode.at [ "props", "amount" ] Json.Decode.int)
        (Json.Decode.at [ "props", "index" ] Json.Decode.int)


encodeRequest : Request -> Json.Decode.Value
encodeRequest request =
    case request of
        GetCurrentQuestion ->
            Json.Encode.object
                [ ( "request", Json.Encode.string "CURRENT_QUESTION" ) ]

        SetAnswer answer ->
            Json.Encode.object
                [ ( "request", Json.Encode.string "SET_ANSWER" )
                , ( "props"
                  , Json.Encode.object
                        [ ( "answer", Json.Encode.string answer )
                        ]
                  )
                ]

        JoinRoom roomName ->
            Json.Encode.object
                [ ( "JOIN_ROOM", Json.Encode.string roomName ) ]


type Response
    = CurrentQuestion QuestionSet
    | Opened
    | CurrentPlayerCount Int
    | CurrentPlayerNames (List String)
    | CurrentQuestionInfo Int Int
    | NoSuchRoom


type Request
    = GetCurrentQuestion
    | SetAnswer String
    | JoinRoom String


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen "ws://localhost:8888/websocket" ParseWebsocketMessage
