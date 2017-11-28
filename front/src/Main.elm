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
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Row as Row
import Bootstrap.Grid.Col as Col
import Bootstrap.Alert as Alert
import Bootstrap.CDN as CDN
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Progress as Progress
import Bootstrap.Table as Table
import DataGrid as DataGrid


host : String
host =
    "http://localhost:8081"


type alias DataRow =
    Dict String String


type alias Model =
    { status : Maybe Status
    , collectionNames : Maybe (List String)
    , currentCollection : CurCollection
    }


type CurCollection
    = Fetched DataGrid.Model
    | NotFetched


init : Location -> ( Model, Cmd Msg )
init location =
    ( { status = Just StatusFetchingData
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
    | ClearStatus
    | DataGridChange DataGrid.Msg


type Status
    = StatusOk
    | StatusFetchingData
    | StatusServerError Http.Error
    | StatusClickedHeader String



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
            ( { model | status = Just StatusFetchingData }, getCollections )

        FetchCollection collectionName ->
            ( { model | status = Just StatusFetchingData }, getCollection collectionName )

        AllCollectionsFetched (Ok collections) ->
            ( { model
                | collectionNames = Just collections
                , status = Just StatusOk
              }
            , Cmd.none
            )

        AllCollectionsFetched (Err error) ->
            ( { model
                | status = Just (StatusServerError error)
              }
            , Cmd.none
            )

        CollectionFetched collName (Ok rows) ->
            ( { model
                | currentCollection = (Fetched (DataGrid.Model collName rows))
                , status = Just StatusOk
              }
            , Cmd.none
            )

        CollectionFetched collName (Err error) ->
            ( { model
                | currentCollection = NotFetched
                , status = Just (StatusServerError error)
              }
            , Cmd.none
            )

        ClearStatus ->
            ( { model | status = Nothing }, Cmd.none )

        DataGridChange gridMsg ->
            case gridMsg of
                DataGrid.ClickHeader title ->
                    ( { model | status = Just (StatusClickedHeader title) }, Cmd.none )


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
                    , ( "z-index", "9999" )
                    ]
                ]
            ]
            [ (Grid.col [ Col.attrs [ onClick ClearStatus ] ] [ drawStatus model.status ]) ]
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


drawStatus : Maybe Status -> Html Msg
drawStatus status =
    case status of
        Nothing ->
            span [] []

        Just StatusOk ->
            Alert.success [ text "Success" ]

        Just StatusFetchingData ->
            Progress.progress
                [ Progress.value 100
                , Progress.animated
                , Progress.label "Fetching..."
                , Progress.height 32
                ]

        Just (StatusServerError error) ->
            Alert.danger
                [ text (httpErrorToString error)
                ]

        Just (StatusClickedHeader title) ->
            Alert.info
                [ text ("A header was clicked: " ++ title)
                ]


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

        Fetched gridModel ->
            DataGrid.view gridModel |> Html.map DataGridChange


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



-- MAIN


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { view = view
        , update = update
        , subscriptions = subscriptions
        , init = init
        }
