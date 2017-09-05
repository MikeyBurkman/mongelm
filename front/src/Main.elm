module Main exposing (..)

import Json.Decode as Decode
import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Navigation exposing (Location)
import UrlParser exposing ((</>))
import Dict exposing (Dict)
import Set exposing (Set)
import Bootstrap.Grid.Row as Row
import Bootstrap.Alert as Alert
import Bootstrap.CDN as CDN
import Bootstrap.Grid as Grid
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Progress as Progress
import Bootstrap.Table as Table


host : String
host =
    "http://localhost:8081"


type alias DataRow =
    Dict String String


type alias Model =
    { status : Status
    , collectionNames : Maybe (List String)
    , currentCollection : CurCollection
    }


type CurCollection
    = Fetched ( String, List DataRow )
    | NotFetched


init : Location -> ( Model, Cmd Msg )
init location =
    ( { status = StatusFetchingData
      , collectionNames = Nothing
      , currentCollection = NotFetched
      }
    , getCollections
    )


type Msg
    = UrlChange Location
    | FetchAllCollections
    | FetchCollection String
    | AllCollectionsFetched (Result Http.Error (List String))
    | CollectionFetched String (Result Http.Error (List (Dict String String)))


type Status
    = StatusOk
    | StatusFetchingData
    | StatusServerError Http.Error



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
                | status = StatusServerError error
              }
            , Cmd.none
            )

        CollectionFetched collName (Ok rows) ->
            ( { model
                | currentCollection = (Fetched ( collName, rows ))
                , status = StatusOk
              }
            , Cmd.none
            )

        CollectionFetched collName (Err error) ->
            ( { model
                | currentCollection = NotFetched
                , status = StatusServerError error
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
        Http.send (CollectionFetched name) request



-- View


view : Model -> Html Msg
view model =
    Grid.container []
        [ CDN.stylesheet
        , Grid.row
            [ Row.attrs
                [ style
                    [ ( "position", "fixed" )
                    , ( "top", "0" )
                    , ( "width", "100%" )
                    , ("z-index", "9999")
                    ]
                ]
            ]
            [ (Grid.col [] [ drawStatus model.status ]) ]
        , Grid.row
            [ Row.attrs
                [ style
                    [ ( "margin-top", "60px" )
                    ]
                ]
            ]
            [ (Grid.col [] [ drawCollections model.collectionNames ]) ]
        , Grid.row [] [ (Grid.col [] [ drawFetchedData model.currentCollection ]) ]
        ]


drawStatus : Status -> Html Msg
drawStatus status =
    case status of
        StatusOk ->
            Alert.success [ text "Success" ]

        StatusFetchingData ->
            Progress.progress
                [ Progress.value 100
                , Progress.animated
                , Progress.label "Fetching..."
                , Progress.height 32
                ]

        StatusServerError error ->
            Alert.danger [ text (httpErrorToString error) ]


drawCollections : Maybe (List String) -> Html Msg
drawCollections collectionsMaybe =
    case collectionsMaybe of
        Nothing ->
            span [] []

        Just collectionNames ->
            collectionNames
                |> List.map drawCollectionName
                |> ListGroup.ul


drawCollectionName : String -> ListGroup.Item Msg
drawCollectionName name =
    ListGroup.li [ ListGroup.attrs [ (onClick (FetchCollection name)) ] ] [ text name ]


drawFetchedData : CurCollection -> Html Msg
drawFetchedData collection =
    case collection of
        NotFetched ->
            div [] [ h3 [] [ text "No Data To Display" ] ]

        Fetched ( name, data ) ->
            let
                allKeys =
                    getAllRowKeys data

                drawHeader name =
                    Table.th [] [ text name ]
            in
                div []
                    [ h3 [] [ text name ]
                    , Table.table
                        { options = [ Table.striped, Table.hover, Table.bordered ]
                        , thead = Table.simpleThead (List.map drawHeader allKeys)
                        , tbody = Table.tbody [] (drawCollectionData allKeys data)
                        }
                    ]


drawCollectionData : List String -> List DataRow -> List (Table.Row Msg)
drawCollectionData keys rows =
    let
        getVal : String -> DataRow -> String
        getVal key row =
            case (Dict.get key row) of
                Nothing ->
                    ""

                Just val ->
                    val

        drawRow : DataRow -> Table.Row Msg
        drawRow row =
            Table.tr [] (List.map (\key -> Table.td [] [ text (getVal key row) ]) keys)
    in
        List.map drawRow rows


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.Timeout ->
            "Network Timeout"

        Http.NetworkError ->
            "Network Error"

        Http.BadUrl s ->
            "Bad Url: " ++ s

        Http.BadStatus resp ->
            (toString resp.status.code) ++ ": " ++ resp.body

        Http.BadPayload message _ ->
            "Parsing Error: " ++ message



-- MISC


getAllRowKeys : List DataRow -> List String
getAllRowKeys rows =
    List.map Dict.keys rows
        |> List.map Set.fromList
        |> List.foldl Set.union Set.empty
        |> Set.toList



-- MAIN


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { view = view
        , update = update
        , subscriptions = subscriptions
        , init = init
        }
