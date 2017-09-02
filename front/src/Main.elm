module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


type alias Model =
    { fetching : Bool
    , loadedData : Maybe (List String)
    }


initModel : Model
initModel =
    { fetching = False
    , loadedData = Nothing
    }


type Msg
    = FetchCollection String
    | CollectionFetched (List String)


update : Msg -> Model -> Model
update msg model =
    model


view : Model -> Html Msg
view model =
    text "FOO"


main : Program Never Model Msg
main =
    Html.beginnerProgram
        { model = initModel
        , view = view
        , update = update
        }
