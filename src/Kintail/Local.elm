module Kintail.Local exposing (url)


url : String -> String
url path =
    "https://kintail/local/" ++ path
