module Page.Game.View exposing (..)

import Style
import Color
import Style.Color as Color
import Style.Font as Font
import Style.Border as Border
import Element exposing (Element)
import Element.Attributes exposing (..)
import Element.Events exposing (onClick)
import List.Extra as List
import Html
import Data.QuestionSet exposing (QuestionSet)
import Page.Game.Update exposing (..)
import Page.Game.Model exposing (..)


type MyStyles
    = Title
    | UpStyle
    | PossibleAnswer
    | PossibleAnswers
    | ShownQuestion
    | NoStyle
    | RedPossibleAnswer
    | YellowPossibleAnswer
    | BluePossibleAnswer
    | GreenPossibleAnswer
    | AnswerText
    | QuestionText


stylesheet : Style.StyleSheet MyStyles variation
stylesheet =
    Style.styleSheet
        [ Style.style Title
            [ Font.size 20 -- all units given as px
            ]
        , Style.style RedPossibleAnswer
            [ Color.background <| Color.rgb 240 0 0
            , Border.rounded 10
            ]
        , Style.style BluePossibleAnswer
            [ Color.background <| Color.rgb 0 0 240
            , Border.rounded 10
            ]
        , Style.style YellowPossibleAnswer
            [ Color.background <| Color.rgb 239 180 0
            , Border.rounded 10
            ]
        , Style.style GreenPossibleAnswer
            [ Color.background <| Color.rgb 110 230 0
            , Border.rounded 10
            ]
        , Style.style AnswerText
            [ Color.text <| Color.rgb 255 255 255
            , Font.size 120
            , Font.typeface [ Font.serif ]
            , Font.center
            ]
        , Style.style QuestionText
            [ Font.size 80
            , Font.typeface [ Font.serif ]
            , Font.center
            ]
        , Style.style NoStyle []
        ]


type alias ElementStyle variation =
    Element MyStyles variation Msg


viewQuestion : QuestionSet -> ElementStyle var
viewQuestion set =
    Element.text set.question
        |> (\inner -> Element.paragraph QuestionText [ width fill, height fill ] [ inner ])
        |> Element.el NoStyle [ Element.Attributes.verticalCenter, Element.Attributes.center ]
        |> Element.el ShownQuestion
            [ minHeight (px 200)
            , height (percent 30)
            , maxWidth (percent 100)
            , Element.Attributes.verticalCenter
            ]


viewPossibleAnswer : String -> MyStyles -> ElementStyle var
viewPossibleAnswer answer color =
    Element.text answer
        |> (\inner -> Element.paragraph AnswerText [ width fill ] [ inner ])
        |> Element.el NoStyle [ Element.Attributes.verticalCenter, Element.Attributes.center ]
        |> Element.button color
            [ onClick (AnswerGiven answer)
            , height fill
            , width fill
            , Element.Attributes.maxWidth (Element.Attributes.percent 50)
            ]


viewAnswers : QuestionSet -> ElementStyle var
viewAnswers set =
    let
        get i =
            set.answers
                |> List.getAt i
                |> Maybe.withDefault ""

        ( green, blue, yellow, red ) =
            ( get 0, get 1, get 2, get 3 )
    in
        Element.column
            NoStyle
            [ spacing 20, height fill ]
            [ Element.wrappedRow NoStyle
                [ width fill, height fill, spacing 20 ]
                [ viewPossibleAnswer green GreenPossibleAnswer
                , viewPossibleAnswer blue BluePossibleAnswer
                ]
            , Element.wrappedRow NoStyle
                [ Element.Attributes.spread
                , height fill
                , spacing 20
                ]
                [ viewPossibleAnswer yellow YellowPossibleAnswer
                , viewPossibleAnswer red RedPossibleAnswer
                ]
            ]


centeredText : String -> Element MyStyles b c
centeredText text =
    Element.text text
        |> Element.el NoStyle [ Element.Attributes.center, Element.Attributes.verticalCenter ]


viewPreGame : Model -> ElementStyle var
viewPreGame model =
    Element.wrappedColumn
        NoStyle
        [ center, Element.Attributes.verticalCenter, height fill, width fill ]
        [ Element.row NoStyle [] [ centeredText <| "Waiting for players! Room name:" ++ model.roomName ]
        , Element.row NoStyle [] [ centeredText <| toString model.currentPlayerCount ++ " players joined so far!" ]
        ]


view : Model -> Html.Html Msg
view model =
    if model.isStarted then
        Element.wrappedColumn
            NoStyle
            [ Element.Attributes.verticalSpread, height fill, width fill ]
            [ Element.text <| "There are currently " ++ toString model.currentPlayerCount ++ " players"
            , "Currently on the "
                ++ toString (model.questionIndex + 1)
                ++ " question out of "
                ++ toString model.questionAmount
                |> Element.text
            , viewQuestion model.set
            , viewAnswers model.set
            , Element.el NoStyle [] Element.empty
            ]
            |> Element.viewport stylesheet
    else
        viewPreGame model
            |> Element.viewport stylesheet
