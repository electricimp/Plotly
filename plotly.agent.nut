// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class Plotly {
    
    // Use this function to get a timestamp that Plotly will automatically 
    // recognize and style correctly.
    static function getPlotlyTimestamp() {
        local timestamp = date();
        return format("%04i-%02i-%02i %02i:%02i:%02i",
            timestamp.year, timestamp.month, timestamp.day,
            timestamp.hour, timestamp.min, timestamp.sec);
    }
    
    static PLOTLY_ENDPOINT = "https://plot.ly/clientresp";
    static PLOTLY_PLATFORM = "electricimp"
    
    static PlotlyMessageType = {
        plot = "plot",
        style = "style",
        layout = "layout"
    }


    _filename = "";
    _url = "";
    _username = "";
    _userKey = "";
    _filename = "";
    _worldReadable = false;
    _persistentLayout = null;
    _persistentStyle = null;
    _hack_sent_first_plot = false; 

    
    function constructor(username, userKey, filename, worldReadable, traces) {
        _username = username;
        _userKey = userKey;
        _filename = filename;
        _worldReadable = worldReadable;
        _persistentLayout = {"xaxis" : {}, "yaxis" : {}};
        _persistentStyle = [];
        local plotlyInput = [];
        foreach(trace in traces) {
            plotlyInput.append({
                "x" : [],
                "y" : [],
                "name" : trace
            });
            _persistentStyle.append({
                "name" : trace  
            });
        };
        _makeApiCall(PlotlyMessageType.plot, plotlyInput, true);
    }
    
    function getUrl() {
        return _url;
    }
    
    // Each dataObj is a table with the following fields:
    // name - A string representing the trace name.
    // x - A numeric or string array representing x-values.
    // y - A numeric or string array representing y-values.
    // z - A numeric or string array representing z-values. Optional.
    function post(dataObj1, ...) {
        local plotlyInput = vargv;
        plotlyInput.insert(0, dataObj1);
        _makeApiCall(PlotlyMessageType.plot, plotlyInput);
        _hack_sent_first_plot = true; 
    }
    
    function setTitle(title) {
        _persistentLayout["title"] <- title;
        _makeApiCall(PlotlyMessageType.layout, _persistentLayout);
    }
    
    function setAxisTitles(xAxisTitle, yAxisTitle) {
        if(xAxisTitle != null && xAxisTitle.len() > 0) {
            _persistentLayout["xaxis"]["title"] <- xAxisTitle;
        }
        if(yAxisTitle != null && yAxisTitle.len() > 0) {
            _persistentLayout["yaxis"]["title"] <- yAxisTitle;
        }
        _makeApiCall(PlotlyMessageType.layout, _persistentLayout);
    }
    
    // trace1, etc. should be the names of traces that will use the new axis.
    function addSecondYAxis(axisTitle, trace1, ...) {
            _persistentLayout["yaxis2"] <-  {
                                                "title" : axisTitle,
                                                "side" : "right",
                                                "overlaying" : "y"
                                            };
            local affectedTraces = vargv;
            affectedTraces.append(trace1);
            foreach(trace in _persistentStyle) {
                if(affectedTraces.find(trace["name"]) != null) {
                    trace["yaxis"] <- "y2";
                }
            }
            _makeApiCall(PlotlyMessageType.layout, _persistentLayout);
            setStyleDirectly(_persistentStyle);
    }
    
    // See the Plotly API docs at https://plot.ly/rest/ for details on how to 
    // format styleTable.  Note that this will overwrite any previously set 
    // style options (e.g. from AddSecondAxis).
    function setStyleDirectly(styleTable) {
        _persistentStyle = styleTable;
        if(_hack_sent_first_plot) {
            _makeApiCall(PlotlyMessageType.style, _persistentStyle);
        } else {
            local makeCallFunction = function() {
                _makeApiCall(PlotlyMessageType.style, _persistentStyle);
            };
            imp.wakeup(2, makeCallFunction.bindenv(this));
        }
    }
    
    // See the Plotly API docs at https://plot.ly/rest/ for details on how to 
    // format layoutTable.  Note that this will overwrite any previously set
    // layout options (e.g. from setTitle or setAxisTitles).
    function setLayoutDirectly(layoutTable) {
        _persistentLayout = layoutTable;
        _makeApiCall(PlotlyMessageType.layout, _persistentLayout);
    }
    

    /******************** PRIVATE FUNCTIONS (DO NOT CALL) ********************/
    function _makeApiCall(type, requestArgs, synchronous = false) {
        local requestKwargs = {
                "filename" : _filename,
                "fileopt" : "extend",
                "world_readable" : _worldReadable
        };
        
        local requestData = {
            "un" : _username,
            "key" : _userKey,
            "origin" : type,  
            "platform" : PLOTLY_PLATFORM,
            "args" : http.jsonencode(requestArgs),
            "kwargs" : http.jsonencode(requestKwargs)
        };
        
        local requestString = http.urlencode(requestData);
        local request = http.post(PLOTLY_ENDPOINT, {}, requestString); 
        
        local requestCallback = function(response) {
            if(response.statuscode == 200) {
                local responseTable = http.jsondecode(response.body);
                if(responseTable.url.len() > 0) {
                    _url = responseTable.url;
                }
                if(responseTable.message.len() > 0) {
                    server.log("Plotly message: " + responseTable.message);
                }
                if(responseTable.warning.len() > 0) {
                    server.log("Plotly warning: " + responseTable.warning);
                }
                if(responseTable.error.len() > 0) {
                    server.log("Plotly error: " + responseTable.error);
                }
            } else {
                server.log("Error sending request: code "
                + statuscode
                + "\n" + response.body);
            }
        };
        
        if(synchronous) {
            local response = request.sendsync();
            requestCallback(response);
        } else {
            request.sendasync(requestCallback.bindenv(this));
        }
    }
}

// Example code showing minimal usage of the library:

function postToPlotly(reading) {
    local timestamp = plot1.getPlotlyTimestamp();
    plot1.post(
        {
            "name" : "temperature",
            "x" : [timestamp],
            "y" : [reading["temp"]]
        });
}

device.on("reading", postToPlotly);

plot1 <- Plotly("my_name", "my_api_key", "my_file_name", true, ["temperature"]);
server.log("See plot at " + plot1.getUrl());
