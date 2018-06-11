# Embedding an `elm-vega` plot in an elm application

The current documentation for [elm-vega](https://github.com/gicentre/elm-vega)
instructs the user to attach Vega-Lite to a static `div` defined an html file.
This example illustrates one approach to embedding an `elm-vega` visualization
in a node defined in an elm application.

## Base Application

I started with the [Random Example](https://guide.elm-lang.org/architecture/effects/random.html) from the elm guide and make the following
changes.

* Make `dieFace` a `Maybe Int`.
* Add a `List(Int)` to the model, which will be used to capture the roll history.
* Refactor the update function using extensible records.

## Embedding an `elm-vega` histogram.

The first step in embedding the histogram is setting up the Vega spec.  We will
use the following function to set up the spec, which sets `model.rolls` as a
data column labeled `X`, then sets of the proper encoding and specification.



```elm
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
```

The port, named `elmToJs`, is set up as follows.

```elm
-- send spec to vega
port elmToJS : Spec -> Cmd msg
```

Next, we need to make a `port` that will be used to pass this spec to the
vega-lite runtime.  First, change the module to a port module by changing the
first line of the `EmbedVega.elm` file as follows

```elm
port module EmbedVega exposing(elmToJS)
```

To make use of this port, we need to add a command to the update function.  This
can be accomplished while updating a `NewRoll` by passing the updated model
through `spec` and `elmToJs`., as shown below.

```elm
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

```

Finally, we need to create a labeled `div` in the view which will be used to
attach the histogram.  We give this `div` the `id` of `"vis"`, which will be
referenced in the associated html file.

```elm
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

```


This program will be compile to `main.js` using

```bash
elm-make src/EmbedVega.elm --output main.js
```

### Setting up `index.html`

Following the advice found in an answer to [this Stack Overflow
question](https://stackoverflow.com/questions/38952724/how-to-coordinate-rendering-with-port-interactions-elm-0-17),
I was able to get this all working using the following set up in html.


```html
<!DOCTYPE html>
<html lang="en">
<head>
  <title>Embed Vega</title>

  </head>

    <!-- These scripts link to the Vega-Lite runtime -->
  <script src="https://cdn.jsdelivr.net/npm/vega@3"></script>
  <script src="https://cdn.jsdelivr.net/npm/vega-lite@2"></script>
  <script src="https://cdn.jsdelivr.net/npm/vega-embed@3"></script>
  <script src="main.js"></script>

</head>
<body>

<div id="app"></div>
<script>
    var node = document.getElementById('app');
    var app = Elm.EmbedVega.embed(node);

    var requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame;

  let updateChart = function(spec){
    console.log(spec);
    requestAnimationFrame(function(){
      vegaEmbed("#vis", spec, {actions: false}).catch(console.warn);
      });
   }

    app.ports.elmToJS.subscribe(updateChart);
</script>
    
</body>
</html>

```

The key things to note are

1. The scripts that load `vega-lite` and `main.js` (the file created in the last
   step).
2. `requestAnimationFrame` is used to sync the elm creation of the `"vis"`
   element and the subsequent manipulation of this `div` by `vega-lite`.
3. We pass `"#vis"` to `vegaEmbed` to embed the visualization in the correct
   location.
