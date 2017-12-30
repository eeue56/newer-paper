module Page.Update exposing (..)

import Page.Model exposing (Model(..))
import Page.Game.Model exposing (decodeRoomname)
import Page.Game.Update exposing (initWithRoomName, Msg(NoRoomFound))
import Page.Welcome.Update exposing (Msg(JoinedRoom))
import Page.Ports as Ports
import Json.Decode


type Msg
    = GameUpdate Page.Game.Update.Msg
    | WelcomeUpdate Page.Welcome.Update.Msg
    | PortUpdate Ports.JsToElm


type alias Flags =
    Json.Decode.Value


init : Flags -> ( Model, Cmd Msg )
init flags =
    case Json.Decode.decodeValue Page.Game.Model.decodeRoomname flags |> Debug.log "room name" of
        Err _ ->
            unwrap WelcomeModel WelcomeUpdate (Page.Welcome.Update.init)

        Ok roomName ->
            unwrap GameModel GameUpdate (Page.Game.Update.initWithRoomName roomName)


update : Msg -> Model -> ( Model, Cmd Msg )
update middleMsg middleModel =
    case ( middleMsg, middleModel ) of
        ( WelcomeUpdate (JoinedRoom roomName), _ ) ->
            Page.Game.Update.initWithRoomName roomName
                |> unwrap GameModel GameUpdate

        ( GameUpdate NoRoomFound, GameModel model ) ->
            unwrap WelcomeModel WelcomeUpdate (Page.Welcome.Update.init)

        ( GameUpdate msg, GameModel model ) ->
            Page.Game.Update.update msg model
                |> unwrap GameModel GameUpdate

        ( WelcomeUpdate msg, WelcomeModel model ) ->
            Page.Welcome.Update.update msg model
                |> unwrap WelcomeModel WelcomeUpdate

        ( PortUpdate msg, model ) ->
            case msg of
                Ports.IncomingLocalStorage incoming ->
                    case Json.Decode.decodeValue decodeRoomname incoming of
                        Err e ->
                            ( model, Cmd.none )

                        Ok roomName ->
                            initWithRoomName roomName
                                |> unwrap GameModel GameUpdate

                Ports.IgnoreableMessage ->
                    ( model, Cmd.none )

        _ ->
            ( middleModel, Cmd.none )


portSubscriptions : Model -> Sub Msg
portSubscriptions model =
    Ports.fromJsToElm
        |> Sub.map PortUpdate


childSubscriptions : Model -> Sub Msg
childSubscriptions middleModel =
    case middleModel of
        GameModel model ->
            Page.Game.Update.subscriptions model
                |> Sub.map GameUpdate

        _ ->
            Sub.none


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ portSubscriptions model
        , childSubscriptions model
        ]


unwrap : (model -> Model) -> (a -> Msg) -> ( model, Cmd a ) -> ( Model, Cmd Msg )
unwrap mapModel msg ( model, cmd ) =
    ( mapModel model, Cmd.map msg cmd )
