# Plotly

This library wraps the [Plotly REST API] (https://plot.ly/rest/), allowing you to graph and style data obtained from Imp-connected sensors.

This class allows for simple creation of time-series data graphs while exposing access for styling graphs using all features of the Plotly API.  It also handles logging messages and errors returned by the Plotly API.

## Constructor: Plotly(*userName, userKey, FileName, worldReadable, traces*)

To create a plot, you need to call the constructor with your Plotly authentication information and some basic data about the new graph.

To find your *userName* and *userKey*, go to the Plotly settings and copy the Username and API key as highlighted below.  Note that the *userKey* is **not** your password, but is an API key that Plotly provides for developers.  Whenever you cycle your API key (e.g. by clicking "Generate a new key"), you will have to update this value in your code as well.

![Plotly settings screenshot] (images/plotly_user_settings.png)

Let *fileName* be the file name you would like this graph to have in your Plotly account.

Let *worldReadable* be true if you would like this graph to be accessible to anyone with a link to the plot.  If this is false, the graph will only be accessible to your account by viewing the plots you own.

Let *traces* be a list of the data point names you would like to graph.  Each Plotly graph can display many concurrent values known as traces, but you must list them all here before plotting them.

```squirrel
myPlot <- Plot("<YOUR_USERNAME>", "<YOUR_API_KEY>", "weather_data", true, ["temperature", "inside_humidity", "outside_humidity"]);
```


## Plotly.getUrl()

Returns a string with the URL of the graph that this object generates.  Note that if *worldReadable* was set to false in the constructor, this link will only be viewable when logged into Plotly.

```squirrel
local plotUrl = myPlot.getUrl();
```

## Plotly.setTitle(*title*)

Sets the title that will be displayed on this graph.

```squirrel
myPlot.setTitle("Weather at Station 7");
```

## Plotly.setAxisTitles(*xAxisTitle, yAxisTitle*)

Sets the labels that will be applied to the standard x- and y-axes on this graph.  If either argument is null or empty, that axis title will not be changed.

```squirrel
myPlot.setAxisTitles("Time", "Temperature (°F)");
```

## Plotly.addSecondYAxis(*axisTitle, trace1, ...*)

Adds a second y-axis on the right side of the graph and assigns the specified traces to it.  *trace1* and all following arguments should be the string names of traces as passed in the *traces* argument to the constructor.

```squirrel
myPlot.addSecondYAxis("Humidity (%)", "inside_humidity", "outside_humidity");
```

## Plotly.setStyleDirectly(*styleTable*)

Sets the style of the graph by passing a description directly to the Plotly API.  This allows for advanced styling options that this library does not have specific methods for.

*styleTable* should be a Squirrel list or table that will be parsed into JSON.  See the [Plotly API docs] (https://plot.ly/rest/) for details on how to format this argument.

Note that there are several caveats to using this method:

- This will entirely overwrite style parameters previously set using methods like `AddSecondAxis` or `setStyleDirectly`.
- If there is an error in formatting *styleTable*, an error may be printed to the console or the call may silently fail.

```squirrel
local style =
[
    {
        "name" : "temperature",
        "type": "scatter",
        "marker": {"symbol": "square", "color": "purple"}
    },
    {
        "name" : "inside_humidity",
        "type": "scatter",
        "marker": {"symbol": "circle", "color": "red"}
    }
];
myPlot.setStyleDirectly(style);
```

## Plotly.setLayoutDirectly(*layoutTable*)

See documentation for `setStyleDirectly`.

## Plotly.plot(*dataObj1, ...*)

Appends data to the Plotly graph.  This method takes an arbitrary number of *dataObj*'s, which are Squirrel tables in the following form:

```squirrel
{
    "name" : <TRACE_NAME>,
    "x" : [<X_VALUE_1, X_VALUE_2, ...>],
    "y" : [<Y_VALUE_1, Y_VALUE_2, ...>]
    "z" : [<OPTIONAL_Z_VALUE_1>, <OPTIONAL_Z_VALUE_2>, ...]
}
```

Note that the "x", "y", and "z" fields hold arrays of integers or strings and the "z" field is optional.

Each *dataObj* must have a name field that corresponds to a trace name as passed into the constructor.  To add multiple data points to a trace, either add them to the traces data arrays or make multiple calls to this method.

```squirrel
myPlot.post(
    {
        "name" : "temperature",
        "x" : [timestamp],
        "y" : [latest_temperature]
    },
    {
        "name" : "inside_humidity",
        "x" : [timestamp],
        "y" : [latest_humidity]
    });
```

## License

The Plotly library is licensed under the [MIT License](./LICENSE).

