module Main exposing (..)

import Json.Decode as Decode
import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Navigation exposing (Location)
import UrlParser exposing ((</>))
import Dict exposing (Dict)


host : String
host =
    "http://localhost:8081"


type alias Model =
    { status : Status
    , collectionNames : Maybe (List String)
    , fetchedCollection : Maybe (List (Dict String String))
    }


init : Location -> ( Model, Cmd Msg )
init location =
    ( { status = StatusFetchingData
      , collectionNames = Nothing
      , fetchedCollection = Nothing
      }
    , getCollections
    )


type Msg
    = UrlChange Location
    | FetchAllCollections
    | FetchCollection String
    | AllCollectionsFetched (Result Http.Error (List String))
    | CollectionFetched (Result Http.Error (List (Dict String String)))


type Status
    = StatusOk
    | StatusFetchingData
    | StatusServerError String



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- Update


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            ( model, Cmd.none )

        FetchAllCollections ->
            ( { model | status = StatusFetchingData }, getCollections )

        FetchCollection collectionName ->
            ( { model | status = StatusFetchingData }, getCollection collectionName )

        AllCollectionsFetched (Ok collections) ->
            ( { model
                | collectionNames = Just collections
                , status = StatusOk
              }
            , Cmd.none
            )

        AllCollectionsFetched (Err error) ->
            ( { model
                | status = StatusServerError "Error hitting server"
              }
            , Cmd.none
            )

        CollectionFetched (Ok rows) ->
            ( { model
                | fetchedCollection = Just rows
                , status = StatusOk
              }
            , Cmd.none
            )

        CollectionFetched (Err error) ->
            ( { model
                | status = StatusServerError "Error hitting server"
              }
            , Cmd.none
            )


getCollections : Cmd Msg
getCollections =
    let
        url =
            host ++ "/collections"

        request =
            Http.get url (Decode.list Decode.string)
    in
        Http.send AllCollectionsFetched request


getCollection : String -> Cmd Msg
getCollection name =
    let
        url =
            host ++ "/collection/" ++ name

        request =
            Http.get url (Decode.list (Decode.dict Decode.string))
    in
        Http.send CollectionFetched request



-- View


view : Model -> Html Msg
view model =
    div []
        [ drawStatus model.status
        , drawCollections model.collectionNames
        , drawFetchedData model.fetchedCollection
        ]


drawCollections : Maybe (List String) -> Html Msg
drawCollections collectionsMaybe =
    case collectionsMaybe of
        Nothing ->
            span [] []

        Just collectionNames ->
            collectionNames
                |> List.map drawCollectionName
                |> div []


drawStatus : Status -> Html Msg
drawStatus status =
    case status of
        StatusOk ->
            span [] []

        StatusFetchingData ->
            h4 []
                [ text "FETCHING DATA..."
                ]

        StatusServerError error ->
            h4 []
                [ text ("ERROR: " ++ error)
                ]


drawCollectionName : String -> Html Msg
drawCollectionName name =
    button [ onClick (FetchCollection name) ] [ text name ]

drawFetchedData : Maybe (List (Dict String String)) -> Html Msg
drawFetchedData fetched =
    case fetched of
        Nothing -> span [] []
        Just rows -> drawCollectionData rows

-- TODO
drawCollectionData : List (Dict String String) -> Html Msg
drawCollectionData rows =
    let
        drawRow : Dict String String -> Html Msg
        drawRow row =
            tr [] (List.map (\v -> td [] [ text v ]) (Dict.values row))
    in
        rows
            |> List.map drawRow
            |> table []

-- MAIN


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { view = view
        , update = update
        , subscriptions = subscriptions
        , init = init
        }
