// Agent Code

// Imports
#require "Plotly.class.nut:1.0.1"

// A simple function to post data to Plotly
function postToPlotly(reading) {
    local timestamp = plot1.getPlotlyTimestamp();
    plot1.post([
        { "name" : "Temperature",
          "x" : [timestamp],
          "y" : [reading["temp"]] }
    ]);
}

// This is the callback triggered when Plotly responds to our login attempt
function plotlyCallback(error, response, decoded) {
    if (error) {
        server.error(error);
        return;
    }
    
    // Begin watching for readings sent by the device
    device.on("reading", postToPlotly);
    
    // Log the plot location
    server.log("See plot at " + plot1.getUrl());
}

// This line instantiates a Plotly instance, but all the action occurs
// in the callback function 'plotlyCallback()'
plot1 <- Plotly("my_username", "my_api_key", "my_file_name", true, ["Temperature"], plotlyCallback);
