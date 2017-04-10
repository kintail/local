module Main exposing (..)

import Task
import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Kintail.Local.File as File exposing (File)


type alias Model =
    { selectedFiles : List File
    , currentFileContents : String
    }


type Msg
    = SelectedFiles (List File)
    | ReadFile File
    | FileContents String


init : ( Model, Cmd Msg )
init =
    ( { selectedFiles = [], currentFileContents = "" }, Cmd.none )


handleResponse : Result File.ReadError String -> Msg
handleResponse result =
    case result of
        Ok contents ->
            FileContents contents

        Err _ ->
            FileContents "<error reading file>"


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        SelectedFiles files ->
            ( { selectedFiles = files, currentFileContents = "" }, Cmd.none )

        ReadFile file ->
            ( model, Task.attempt handleResponse (File.read file) )

        FileContents contents ->
            ( { model | currentFileContents = contents }, Cmd.none )


description : File -> String
description file =
    File.name file ++ " (" ++ toString (File.sizeInBytes file) ++ " bytes)"


listElement : File -> Html Msg
listElement file =
    Html.li []
        [ Html.text (description file)
        , Html.button [ Events.onClick (ReadFile file) ] [ Html.text "Read" ]
        ]


view : Model -> Html Msg
view { selectedFiles, currentFileContents } =
    let
        chooserId =
            "fileChooser"

        chooserAttributes =
            [ Attributes.multiple True, Attributes.hidden True ]

        labelText =
            if List.isEmpty selectedFiles then
                "Choose files"
            else
                toString (List.length selectedFiles) ++ " files chosen:"
    in
        Html.div []
            [ File.chooser chooserId SelectedFiles chooserAttributes
            , Html.label [ Attributes.for chooserId ] [ Html.text labelText ]
            , Html.ul [] (List.map listElement selectedFiles)
            , Html.textarea [ Attributes.value currentFileContents ] []
            ]


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
