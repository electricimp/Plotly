# Minimal Setup Plotly Library Example

This example uses the Plotly library to plot data generated from an [Electric Imp Env Tail](https://electricimp.com/docs/tails/env/) with minimal setup.

## Device

The Device code is taken directly from the [Weather Station project](https://electricimp.com/docs/tails/weatherstation/) and sends a table with readings from all of its sensors to the Agent every 5 minutes.

## Agent

The Agent does the following in a series of nested callbacks:

- Creates a publicly viewable plot.
- Registers a function to respond to device data messages.
    - This function generates a Plotly-recognized timestamp and calls the library's `post` method to append temperature data to the plot at the current timestamp.
- Prints the plot URL to the server logs.
