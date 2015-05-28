// Copyright (c) 2015 Electric Imp
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

class Plotly {
    
    static function getPlotlyTimestamp(providedTimestamp = null) {
        local timestamp = providedTimestamp == null ? date() : date(providedTimestamp);
        return format("%04i-%02i-%02i %02i:%02i:%02i",
            timestamp.year, timestamp.month, timestamp.day,
            timestamp.hour, timestamp.min, timestamp.sec);
    }
    
    static PLOTLY_ENDPOINT = "https://plot.ly/clientresp";
    static PLOTLY_PLATFORM = "electricimp"
    
    static MESSAGETYPE_PLOT = "plot";
    static MESSAGETYPE_STYLE = "style";
    static MESSAGETYPE_LAYOUT = "layout";

    _url = null;
    _username = null;
    _userKey = null;
    _filename = null;
    _worldReadable = null;
    _persistentLayout = null;
    _persistentStyle = null;

    function constructor(username, userKey, filename, worldReadable, traces, callback = null) {
        _url = "";
        _username = username;
        _userKey = userKey;
        _filename = filename;
        _worldReadable = worldReadable;
        _persistentLayout = {"xaxis" : {}, "yaxis" : {}};
        _persistentStyle = [];
        local plotlyInput = [];
        
        // Setup blank traces to be appended to later
        foreach(trace in traces) {
            plotlyInput.append({
                "x" : [],
                "y" : [],
                "name" : trace
            });
            _persistentStyle.append({
                "name" : trace  
            });
        }

        _makeApiCall(MESSAGETYPE_PLOT, plotlyInput, callback);
    }
    
    function getUrl() {
        return _url;
    }
    
    function post(dataObjs, callback = null) {;
        _makeApiCall(MESSAGETYPE_PLOT, dataObjs, callback);
    }
    
    function setTitle(title, callback = null) {
        _persistentLayout["title"] <- title;
        _makeApiCall(MESSAGETYPE_LAYOUT, _persistentLayout, callback);
    }
    
    function setAxisTitles(xAxisTitle, yAxisTitle, callback = null) {
        if(xAxisTitle != null && xAxisTitle.len() > 0) {
            _persistentLayout["xaxis"]["title"] <- xAxisTitle;
        }
        if(yAxisTitle != null && yAxisTitle.len() > 0) {
            _persistentLayout["yaxis"]["title"] <- yAxisTitle;
        }
        _makeApiCall(MESSAGETYPE_LAYOUT, _persistentLayout, callback);
    }
    
    function addSecondYAxis(axisTitle, traces, callback = null) {
            _persistentLayout["yaxis2"] <- {
                "title" : axisTitle,
                "side" : "right",
                "overlaying" : "y"
            };
            // Search for requested traces in style table
            foreach(trace in _persistentStyle) {
                if(traces.find(trace["name"]) != null) {
                    trace["yaxis"] <- "y2";
                }
            }
            local secondAxisCallback = _getSecondAxisLayoutCallback(callback).bindenv(this);
            _makeApiCall(MESSAGETYPE_LAYOUT, _persistentLayout, secondAxisCallback);
    }
    
    function setStyleDirectly(styleTable, callback = null) {
        // Note that this overwrites the existing style table
        _persistentStyle = styleTable;
        _makeApiCall(MESSAGETYPE_STYLE, _persistentStyle, callback);
    }
    
    function setLayoutDirectly(layoutTable, callback = null) {
        // Note that this overwrites the existing layout table
        _persistentLayout = layoutTable;
        _makeApiCall(MESSAGETYPE_LAYOUT, _persistentLayout, callback);
    }
    

    /******************** PRIVATE FUNCTIONS (DO NOT CALL) ********************/
    function _getSecondAxisStyleCallback(err1, response1, parsed1, userCallback) {
        return function(err2, response2, parsed2) {
            if(userCallback != null) {
                // Since adding a second y-axis requires two API calls, pass the "worse" response into the user callback
                local returnedResponse = response1.statuscode > response2.statuscode ? response1 : response2;
                local returnedErr = response1.statuscode > response2.statuscode ? err1 : err2;
                local returnedParsed = response1.statuscode > response2.statuscode ? parsed1 : parsed2;
                imp.wakeup(0, @() userCallback(returnedErr, returnedResponse, returnedParsed));
            }
        }
    }
    
    function _getSecondAxisLayoutCallback(userCallback) {
        return function(err1, response1, parsed1) {
            local callback =  _getSecondAxisStyleCallback(err1, response1, parsed1, userCallback);
            setStyleDirectly(_persistentStyle, callback);
        }
    }
    
    function _getApiRequestCallback(userCallback) {
        return function(response){
            local error = null;
            local responseTable = null;
            if(response.statuscode == 200) {
                try{
                    responseTable = http.jsondecode(response.body);
                    if("url" in responseTable && responseTable.url.len() > 0) {
                        _url = responseTable.url;
                    }
                    if("error" in responseTable && responseTable.error.len() > 0) {
                        error = responseTable.error;   
                    }
                } catch(exception) {
                    error = "Could not decode Plotly response";
                }
            } else {
                error = "HTTP Response Code " + response.statuscode;
            }
            if(userCallback != null) {
                imp.wakeup(0, @() userCallback(error, response, responseTable));
            }
        }
    }
    
    function _makeApiCall(type, requestArgs, userCallback) {
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
        
        local apiRequestCallback = _getApiRequestCallback(userCallback);
        request.sendasync(apiRequestCallback.bindenv(this));
    }
}

function loggerCallback(error, response, decoded) {
    if(error == null) {
        server.log(response.body);
    } else {
        server.log(error);
    }
}

function postToPlotly(reading) {
    local timestamp = plot1.getPlotlyTimestamp();
    plot1.post([
        {
            "name" : "Temperature",
            "x" : [timestamp],
            "y" : [reading["temp"]]
        },
        {
            "name" : "Pressure",
            "x" : [timestamp],
            "y" : [reading["pressure"]]
        },
        {
            "name" : "Humidity",
            "x" : [timestamp],
            "y" : [reading["humid"]]
        },
        {
            "name" : "Lux",
            "x" : [timestamp],
            "y" : [reading["lux"]]
        }], loggerCallback);
}

local constructorCallback = function(error, response, decoded) {
    
    if(error == null) {
        device.on("reading", postToPlotly);

        plot1.setTitle("Env Tail Data", function(error, response, decoded) {
            
            if(error == null) {
                plot1.setAxisTitles("time", "Climate", function(error, response, decoded) {
                    
                    if(error == null) {
                        local style =
                        [
                            {
                                "name" : "Temperature",
                                "type": "scatter",
                                "marker": {"symbol": "square", "color": "purple"}
                                
                            },
                            {
                                "name" : "Pressure",
                                "type": "scatter",
                                "marker": {"symbol": "circle", "color": "red"}
                                
                            },
                            {
                                "name" : "Humidity",
                                "type": "scatter", 
                                "marker": {"symbol": "square", "color": "blue"}
                                
                            },
                            {
                                "name" : "Lux",
                                "type": "scatter",
                                "marker": {"symbol": "triangle", "color": "green"}
                                
                            }
                        ];
                        plot1.setStyleDirectly(style, function(error, response, decoded) {
                            
                            if(error == null) {
                                plot1.addSecondYAxis("Light", ["Lux"], function(error, response, decoded) {
                                    
                                    if(error == null){
                                        server.log("See plot at " + plot1.getUrl()); 
                                    } else {
                                        server.log(error);
                                    }
                                });
                            } else {
                                server.log(error);
                            }
                        });
                    } else {
                        server.log(error);
                    }
                });
            } else {
                server.log(error);
            }
        });
    } else {
        server.log(error);
    }
}

local traces = ["Temperature", "Pressure", "Humidity", "Lux"];
plot1 <- Plotly("my_username", "my_api_key", "my_file_name", true, traces, constructorCallback);
