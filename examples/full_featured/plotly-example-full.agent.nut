#require "Plotly.class.nut:1.0.0"

function loggerCallback(error, response, decoded) {
    if (error == null) {
        server.log(response.body);
    } else {
        server.log(error);
    }
}

function postToPlotly(reading) {
    local timestamp = plot1.getPlotlyTimestamp();
    plot1.post([
        { "name" : "Temperature",
          "x" : [timestamp],
          "y" : [reading["temp"]] },
        { "name" : "Pressure",
          "x" : [timestamp],
          "y" : [reading["pressure"]] },
        { "name" : "Humidity",
          "x" : [timestamp],
          "y" : [reading["humid"]] },
        { "name" : "Lux",
          "x" : [timestamp],
          "y" : [reading["lux"]]}
    ], loggerCallback);
}

local constructorCallback = function(error, response, decoded) {

    if (error != null) {
        server.log(error);
        return;
    }

    device.on("reading", postToPlotly);

    plot1.setTitle("Env Tail Data", function(error, response, decoded) {
        if (error != null) {
            server.log(error);
            return;
        }

        plot1.setAxisTitles("time", "Climate", function(error, response, decoded) {
            if (error != null) {
                server.log(error);
                return;
            }

            local style = [
                { "name" : "Temperature",
                  "type": "scatter",
                  "marker": {"symbol": "square", "color": "purple"} },
                { "name" : "Pressure",
                  "type": "scatter",
                  "marker": {"symbol": "circle", "color": "red"} },
                { "name" : "Humidity",
                  "type": "scatter",
                   "marker": {"symbol": "square", "color": "blue"} },
                { "name" : "Lux",
                  "type": "scatter",
                  "marker": {"symbol": "triangle", "color": "green"} }
            ];
            
            plot1.setStyleDirectly(style, function(error, response, decoded) {
                if (error != null) {
                    server.log(error);
                    return;
                }

                plot1.addSecondYAxis("Light", ["Lux"], function(error, response, decoded) {
                    if (error != null) {
                        server.log(error);
                        return;
                    }

                    server.log("See plot at " + plot1.getUrl());
                });
            });
        });
    });
}

local traces = ["Temperature", "Pressure", "Humidity", "Lux"];
plot1 <- Plotly("my_username", "my_api_key", "my_file_name", true, traces, constructorCallback);
