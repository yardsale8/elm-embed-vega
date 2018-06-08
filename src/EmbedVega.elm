port module EmbedVega exposing(elmToJS)

-- Taken from the elm guide - Random example
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)
import Random
import VegaLite exposing (..)



main =
  Html.program
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL


type alias Model =
  { dieFace : Maybe Int
  , rolls : List(Int)
  }


init : (Model, Cmd Msg)
init =
  (Model Nothing [], Cmd.none)



-- UPDATE


type Msg
  = Roll
  | NewFace Int


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Roll ->
      (model, Random.generate NewFace (Random.int 1 6))

    NewFace newFace ->
        let
            newModel = 
                model
                |> updateFace newFace
                |> updateRolls newFace
        in
            (newModel, elmToJS (spec newModel))


updateFace face model =
    {model | dieFace = Just face}

updateRolls face model =
    {model | rolls = face :: model.rolls}

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- Vega Spec

spec model =
    let

        d = dataFromColumns []
            << dataColumn "X" (nums (List.map toFloat model.rolls))

        enc =
            encoding
                << position X [ pName "X", pMType Quantitative, pBin [] ]
                << position Y [ pAggregate Count, pMType Quantitative]
    in
    toVegaLite
        [ d []
        , bar []
        , enc []
        ]

-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ showCurrentRoll model
    , display "20 Rolls" model.rolls
    , button [ onClick Roll ] [ Html.text "Roll" ]
    , div [id "vis"][]
    ]

showCurrentRoll model =
    case model.dieFace of
        Just i ->
            h1 [] [ Html.text (toString i) ]
        Nothing ->
            h1 [] [ Html.text "Click Roll to roll the die"]



display : String -> a -> Html msg
display name value =
  div [] [ Html.text (name ++ " ==> " ++ toString value) ]



-- send spec to vega
port elmToJS : Spec -> Cmd msg

