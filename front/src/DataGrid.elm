module DataGrid exposing (Model, DataRow, Msg(..), view)

import Dict exposing (Dict)
import Set exposing (Set)
import Html exposing (..)
import Html.Events exposing (onClick)
import Bootstrap.Table as Table


type alias Model =
    { name : String
    , data : List DataRow
    }


type alias DataRow =
    Dict String String


type Msg
    = ClickHeader String


view : Model -> Html Msg
view model =
    let
        name =
            model.name

        data =
            model.data

        allKeys =
            getAllRowKeys data

        drawHeader name =
            Table.th [ Table.cellAttr (onClick (ClickHeader name)) ] [ text name ]
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


getAllRowKeys : List DataRow -> List String
getAllRowKeys rows =
    List.map Dict.keys rows
        |> List.map Set.fromList
        |> List.foldl Set.union Set.empty
        |> Set.toList
