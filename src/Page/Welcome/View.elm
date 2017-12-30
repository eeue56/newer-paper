module Page.Welcome.View exposing (..)

import Page.Welcome.Model exposing (..)
import Page.Welcome.Update exposing (..)
import Element exposing (Element)
import Element.Attributes exposing (..)
import Element.Input
import Element.Events exposing (onClick)
import Style
import Color
import Style.Color as Color
import Style.Border as Border
import Style.Shadow as Shadow
import Html exposing (Html)


type MyStyles
    = RoomNameInput
    | RoomNameJoin
    | CreateNewRoomButtonStyle
    | NoStyle
    | Background


stylesheet : Style.StyleSheet MyStyles variation
stylesheet =
    Style.styleSheet
        [ Style.style NoStyle []
        , Style.style Background
            []
        , Style.style RoomNameInput
            [ Color.border <| Color.rgb 0 0 0
            , Border.solid
            , Border.all 2
            , Shadow.box
                { offset = ( 0, 0 )
                , size = 0.5
                , blur = 2
                , color = Color.blue
                }
            ]
        , Style.style RoomNameJoin
            [ Border.rounded 2
            , Color.border <| Color.rgb 0 0 0
            , Border.solid
            , Border.all 2
            ]
        , Style.style CreateNewRoomButtonStyle
            [ Border.rounded 2
            , Color.border <| Color.rgb 0 0 0
            , Border.solid
            , Border.all 2
            ]
        ]


type alias ElementStyle variation =
    Element MyStyles variation Msg


viewRoomName : String -> ElementStyle variation
viewRoomName roomName =
    Element.row
        NoStyle
        [ spacing 20 ]
        [ Element.Input.text
            RoomNameInput
            [ Element.Attributes.width (px 200)
            , Element.Attributes.padding 10
            ]
            { onChange = ChangeRoomName
            , value = roomName
            , label =
                Element.el
                    NoStyle
                    [ Element.Attributes.verticalCenter
                    , Element.Attributes.center
                    ]
                    (Element.text "Enter your roomname")
                    |> Element.Input.labelAbove
            , options = []
            }
        , Element.button RoomNameJoin
            [ Element.Attributes.paddingXY 20 2
            , Element.Events.onClick (JoinedRoom roomName)
            ]
            (Element.text "Join!")
        ]
        |> Element.el NoStyle
            [ Element.Attributes.center
            , Element.Attributes.verticalCenter
            ]


viewCreateRoom : ElementStyle variation
viewCreateRoom =
    Element.button CreateNewRoomButtonStyle
        [ width (px 200)
        , height (px 100)
        , Element.Attributes.center
        , Element.Attributes.verticalCenter
        , Element.Events.onClick CreateNewRoom
        ]
        (Element.text "Create new room")


viewNewIndex : Model -> ElementStyle variation
viewNewIndex model =
    Element.wrappedColumn
        Background
        [ Element.Attributes.verticalSpread, height fill, width fill ]
        [ Element.el NoStyle [] (Element.text "")
        , viewRoomName model.roomName
        , viewCreateRoom
        , case model.errors of
            [] ->
                Element.text ""

            errors ->
                Element.row NoStyle
                    [ Element.Attributes.center
                    , Element.Attributes.verticalCenter
                    ]
                    (List.map Element.text errors)
        , Element.el NoStyle [] (Element.text "")
        ]


viewRoomInfo : RoomInfo -> ElementStyle variation
viewRoomInfo roomInfo =
    Element.wrappedColumn
        Background
        [ Element.Attributes.verticalSpread, height fill, width fill ]
        [ Element.el NoStyle [] (Element.text "")
        , Element.el NoStyle
            [ Element.Attributes.center
            , Element.Attributes.verticalCenter
            ]
            (Element.text "Tell your friends to join this room!")
        , Element.el NoStyle
            [ Element.Attributes.center
            , Element.Attributes.verticalCenter
            ]
            (Element.text roomInfo.roomName)
        , Element.button RoomNameJoin
            [ onClick (JoinedRoom roomInfo.roomName)
            , height (px 100)
            , width (percent 50)
            , center
            ]
            (Element.text "Join room")
        , Element.el NoStyle [] (Element.text "")
        , Element.el NoStyle [] (Element.text "")
        ]


view : Model -> Html Msg
view model =
    Element.viewport stylesheet <|
        case model.roomInfo of
            Nothing ->
                viewNewIndex model

            Just roomInfo ->
                viewRoomInfo roomInfo
