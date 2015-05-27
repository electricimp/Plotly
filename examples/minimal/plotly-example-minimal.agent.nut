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

    
    function constructor(username, userKey,
                         filename, worldReadable, traces, 
                         callback = null) {
        _url = "";
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
            _persistentLayout["yaxis2"] <-  {
                                                "title" : axisTitle,
                                                "side" : "right",
                                                "overlaying" : "y"
                                            };
            foreach(trace in _persistentStyle) {
                if(traces.find(trace["name"]) != null) {
                    trace["yaxis"] <- "y2";
                }
            }
            _makeApiCall(MESSAGETYPE_PLOT, _persistentLayout, 
                function(response1, plot){
                    setStyleDirectly(_persistentStyle, function(response2, plot) {
                        if(callback != null){
                            local returnedResponse = 
                                response1.statuscode > response2.statuscode ? 
                                response1 : response2;
                            callback(returnedResponse, plot);
                        }
                    });
                });
    }
    
    function setStyleDirectly(styleTable, callback = null) {
        _persistentStyle = styleTable;
        _makeApiCall(MESSAGETYPE_STYLE, _persistentStyle, callback);
    }
    
    function setLayoutDirectly(layoutTable, callback = null) {
        _persistentLayout = layoutTable;
        _makeApiCall(MESSAGETYPE_LAYOUT, _persistentLayout, callback);
    }
    

    /******************** PRIVATE FUNCTIONS (DO NOT CALL) ********************/
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
        
        local requestCallback = function(response) {
            if(response.statuscode == 200) {
                local responseTable = null;
                try{
                    responseTable = http.jsondecode(response.body);
                    if(responseTable.url.len() > 0) {
                        _url = responseTable.url;
                    }
                } catch(exception){
                    server.error("Could not decode Plotly response.");
                }
                response["decoded"] <- responseTable;
            }
            if(userCallback != null){
                userCallback(response, this);
            }
        };
        
        request.sendasync(requestCallback.bindenv(this));
    }
}

function postToPlotly(reading) {
    local timestamp = plot1.getPlotlyTimestamp();
    plot1.post([
        {
            "name" : "Temperature",
            "x" : [timestamp],
            "y" : [reading["temp"]]
        }
    ]);
}

plot1 <- Plotly("my_name", "my_api_key", "my_file_name", true, ["Temperature"], function(response, plot){
    device.on("reading", postToPlotly);
    server.log("See plot at " + plot.getUrl());               
});
