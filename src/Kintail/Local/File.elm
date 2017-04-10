module Kintail.Local.File
    exposing
        ( File
        , ReadError
        , SaveError
        , name
        , sizeInBytes
        , lastModified
        , mimeType
        , chooser
        , read
        , save
        , selectedFiles
        )

import Html exposing (Html)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Encode as Encode exposing (Value)
import Json.Decode as Decode exposing (Decoder)
import Date exposing (Date)
import Task exposing (Task)
import Http
import Kintail.Local as Local


type File
    = File
        { elementId : String
        , index : Int
        , name : String
        , sizeInBytes : Float
        , lastModified : Date
        , mimeType : Maybe String
        }


type ReadError
    = ReadError


type SaveError
    = SaveError


name : File -> String
name (File properties) =
    properties.name


sizeInBytes : File -> Float
sizeInBytes (File properties) =
    properties.sizeInBytes


lastModified : File -> Date
lastModified (File properties) =
    properties.lastModified


mimeType : File -> Maybe String
mimeType (File properties) =
    properties.mimeType


chooser : String -> (List File -> msg) -> List (Html.Attribute msg) -> Html msg
chooser id tag additionalAttributes =
    let
        typeAttribute =
            Attributes.type_ "file"

        idAttribute =
            Attributes.id id

        onChangeAttribute =
            Events.on "change" (selectedFiles |> Decode.map tag)

        attributes =
            typeAttribute
                :: idAttribute
                :: onChangeAttribute
                :: additionalAttributes
    in
        Html.input attributes []


read : File -> Task ReadError String
read file =
    let
        request =
            Http.request
                { method = "POST"
                , headers = []
                , url = Local.url "file/read"
                , body = Http.jsonBody (encode file)
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.toTask request |> Task.mapError (always ReadError)


encode : File -> Value
encode (File properties) =
    let
        lastModifiedTime =
            Date.toTime properties.lastModified

        mimeTypeString =
            Maybe.withDefault "" properties.mimeType
    in
        Encode.object
            [ ( "elementId", Encode.string properties.elementId )
            , ( "index", Encode.int properties.index )
            , ( "name", Encode.string properties.name )
            , ( "size", Encode.float properties.sizeInBytes )
            , ( "lastModified", Encode.float lastModifiedTime )
            , ( "mimeType", Encode.string mimeTypeString )
            ]


save : { contents : String, suggestedFilename : String } -> Task SaveError ()
save { contents, suggestedFilename } =
    let
        encoded =
            Encode.object
                [ ( "contents", Encode.string contents )
                , ( "suggestedFilename", Encode.string suggestedFilename )
                ]

        handleResponse response =
            if response.status.code == 200 then
                Ok ()
            else
                Err "Failed to save file"

        request =
            Http.request
                { method = "PUT"
                , headers = []
                , url = Local.url "file/save"
                , body = Http.jsonBody encoded
                , expect = Http.expectStringResponse handleResponse
                , timeout = Nothing
                , withCredentials = False
                }
    in
        Http.toTask request |> Task.mapError (always SaveError)


selectedFiles : Decoder (List File)
selectedFiles =
    Decode.field "target"
        (Decode.field "id" Decode.string
            |> Decode.andThen (\id -> Decode.field "files" (fileListDecoder id))
        )


fileListDecoder : String -> Decoder (List File)
fileListDecoder id =
    Decode.field "length" Decode.int
        |> Decode.andThen (\length -> accumulateFiles id (length - 1) [])


accumulateFiles : String -> Int -> List File -> Decoder (List File)
accumulateFiles id index accumulated =
    if index >= 0 then
        Decode.field (toString index) (fileDecoder id index)
            |> Decode.andThen
                (\file -> accumulateFiles id (index - 1) (file :: accumulated))
    else
        Decode.succeed accumulated


fileDecoder : String -> Int -> Decoder File
fileDecoder id index =
    let
        toMaybe string =
            if String.isEmpty string then
                Nothing
            else
                Just string

        mimeTypeDecoder =
            Decode.string |> Decode.map toMaybe

        dateDecoder =
            Decode.float |> Decode.map Date.fromTime
    in
        Decode.map4
            (\name sizeInBytes lastModified mimeType ->
                File
                    { elementId = id
                    , index = index
                    , name = name
                    , sizeInBytes = sizeInBytes
                    , lastModified = lastModified
                    , mimeType = mimeType
                    }
            )
            (Decode.field "name" Decode.string)
            (Decode.field "size" Decode.float)
            (Decode.field "lastModified" dateDecoder)
            (Decode.field "type" mimeTypeDecoder)
