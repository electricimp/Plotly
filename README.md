# Plotly #

This library wraps the [Plotly REST API](https://plot.ly/rest/), allowing you to graph and style data obtained from imp-connected sensors.

The class allows for simple creation of time-series data graphs while exposing access for styling graphs using all features of the Plotly API. Note that this library requires the creation of a Plotly account.

**To add this library to your project, add** `#require "Plotly.class.nut:1.0.1"` **to the top of your agent code.**

### Examples ###

To see working examples of this library in use, look at the [Fully-Featured](examples/full_featured) and [Minimal](examples/minimal) Plotly projects.

### Callbacks ###

Almost all methods in this class (including the constructor) take an optional *callback* argument.
This is a function that takes arguments *error*, *response* and *decoded*, where *error* is a string (or `null` if no error occured), *response* is a table representing a response from the Plotly servers, and *decoded* is a table representing the JSON object returned by the Plotly servers. The *response* object mirrors that provided in the callback to the imp API's [httprequest.sendasync()](https://developer.electricimp.com/api/httprequest/sendasync). Make sure to check the *error* argument before using either *response* or *decoded*.

**Note** While the constructor will return immediately, it is only safe to operate on the resulting object **once the callback has been called**. It is the user's responsibility to ensure at this step that the construction has succeeded by checking the HTTP response code and/or Plotly response messages.

## Class Usage ##

### Constructor: Plotly(*userName, userKey, FileName, worldReadable, traces[, callback]*) ###

To create a plot, you need to call the constructor with your Plotly authentication information and some basic data about the new graph.

To find your *userName* and *userKey*, go to the Plotly [API settings page](https://plot.ly/settings/api) and copy the Username and API key as highlighted in the image below. Note that the *userKey* is **not** your password, but is an API key that Plotly provides for developers. Whenever you cycle your API key (eg. by clicking **Generate a new key**), you will have to update this value in your code as well.

![Plotly settings screenshot](images/plotly_user_settings.png)

Set *fileName* to the file name you would like this graph to have in your Plotly account.

Set *worldReadable* to `true` if you would like this graph to be accessible to anyone with a link to the plot. If you pass`false` into *worldReadable*, the graph will only be accessible to your account by viewing the plots you own.

The parameter *traces* takes a list of the data point names you would like to graph. Each Plotly graph can display many concurrent values known as traces, but you must list them all here before plotting them.

```squirrel
#require "Plotly.class.nut:1.0.1"

local callback = function(error, response, decoded){
  if (error) {
    server.log("Got an error: " + error);
    return;
  }
  
  server.log("See plot at " + myPlot.getUrl());
}

myPlot <- Plotly("<YOUR_USERNAME>", "<YOUR_API_KEY>", "weather_data", true, ["temperature", "inside_humidity", "outside_humidity"], callback);
```

## Class Methods ##

### getUrl() ###

This method returns a string with the URL of the graph that this object generates. Note that if you passed `false` into the constructor’s *worldReadable* parameter, this link will only be viewable to users who are logged into Plotly.

#### Example ####

```squirrel
local plotUrl = myPlot.getUrl();
```

### setTitle(*title[, callback]*) ###

This method sets the title that will be displayed on the graph.

#### Example ####

```squirrel
myPlot.setTitle("Weather at Station 7");
```

### setAxisTitles(*xAxisTitle, yAxisTitle*) ###

This method sets the labels that will be applied to the standard x- and y-axes on the graph. If either argument is `null` or empty, that axis’ title will not be changed.

#### Example ####

```squirrel
myPlot.setAxisTitles("Time", "Temperature (°F)");
```

### addSecondYAxis(*axisTitle, traces[, callback]*) ###

This method adds a second y-axis on the right side of the graph and assigns the specified traces to it. The argument passed into *traces* should be an array of names of traces as passed in the constructor’s *traces* parameter.

#### Example ####

```squirrel
myPlot.addSecondYAxis("Humidity (%)", ["inside_humidity", "outside_humidity"]);
```

### setStyleDirectly(*styleTable[, callback]*) ###

This method sets the style of the graph by passing a description directly to the Plotly API. This allows for advanced styling options for which this library does not provides specific methods.

The parameter *styleTable* takes a Squirrel array or table that will be parsed into JSON. Please see the [Plotly API docs](https://plot.ly/rest/) for details on how to format this argument.

You should note that there are several caveats to using this method:

- This will entirely overwrite style parameters previously set using methods like *addSecondYAxis()* or *setStyleDirectly()*.
- If there is an error in the formatting data passed into *styleTable*, an error may be passed to *callback* or the call may silently fail.

#### Example ####

```squirrel
local style = [
  { "name" : "temperature",
    "type": "scatter",
    "marker": { "symbol": "square", 
                "color": "purple" } },
  { "name" : "inside_humidity",
    "type": "scatter",
    "marker": { "symbol": "circle", 
                "color": "red" } }
];

myPlot.setStyleDirectly(style);
```

### setLayoutDirectly(*layoutTable[, callback]*) ###

This method sets the layout of the graph by passing a description directly to the Plotly API. This allows for advanced layout options for which this library does not provides specific methods.

The value passed into *layoutTable* should be a Squirrel array or table that will be parsed into JSON. Please see the [Plotly API docs](https://plot.ly/rest/) for details on how to format this argument.

You should note that there are several caveats to using this method:

- This will entirely overwrite layout parameters previously set using methods like *addSecondYAxis()*, *setTitle()* or *setLayoutDirectly()*.
- If there is an error in formatting *layoutTable*, an error may be passed to *callback* or the call may silently fail.

### post(*dataObjects[, callback]*) ###

This method appends data to the Plotly graph. The parameter *dataObjs* takes an array of Squirrel tables in the following form:

```squirrel
{ "name" : <TRACE_NAME>,
  "x" : [<X_VALUE_1, X_VALUE_2, ...>],
  "y" : [<Y_VALUE_1, Y_VALUE_2, ...>]
  "z" : [<OPTIONAL_Z_VALUE_1>, <OPTIONAL_Z_VALUE_2>, ...] }
```

Note that the *x*, *y* and *z* fields hold arrays of integers or strings, and the *z* field is optional.

Each element in *dataObjects* must have a name field that corresponds to a trace name as passed into the constructor. To add multiple data points to a trace, either add them to the *traces* data arrays *(see above)* or make multiple calls to *post()*.

#### Example ####

```squirrel
myPlot.post([
  { "name" : "temperature",
    "x" : [timestamp],
    "y" : [latest_temperature] },
  { "name" : "inside_humidity",
    "x" : [timestamp],
    "y" : [latest_humidity] }
]);
```

## Static Methods ##

### Plotly.getPlotlyTimestamp(*[timestamp]*) ###

This method returns a timestamp string that Plotly will automatically recognize and style correctly. Use this for your x-value on time-series data.

If the value passed into *timestamp* is a Unix timestamp, this function will output the formatted timestamp corresponding to it.

#### Example ####

```squirrel
local timestamp = Plotly.getPlotlyTimestamp();
myPlot.post(
  { "name" : "temperature",
    "x" : [timestamp],
    "y" : [latest_temperature] });
```

## License ##

The Plotly library is licensed under the [MIT License](./LICENSE).
