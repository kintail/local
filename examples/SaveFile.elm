module Main exposing (..)

import Task
import Html exposing (Html)
import Html.Events as Events
import Kintail.Local.File as File


type alias Model =
    ()


type Msg
    = SaveFile
    | FileSaved
    | ErrorOccurred


view : Model -> Html Msg
view model =
    Html.button [ Events.onClick SaveFile ] [ Html.text "Save file" ]


handleResponse : Result File.SaveError () -> Msg
handleResponse result =
    case result of
        Ok () ->
            FileSaved

        Err _ ->
            Debug.log "Error occurred" ErrorOccurred


update : Msg -> Model -> ( Model, Cmd Msg )
update message () =
    case message of
        SaveFile ->
            ( ()
            , File.save
                { contents = "One line\nAnother line"
                , suggestedFilename = "contents.txt"
                }
                |> Task.attempt handleResponse
            )

        FileSaved ->
            ( (), Cmd.none )

        ErrorOccurred ->
            ( (), Cmd.none )


main =
    Html.program
        { init = ( (), Cmd.none )
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }
