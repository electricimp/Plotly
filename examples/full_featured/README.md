# Full-Featured Plotly Library Example

This example uses all features of the Plotly library to plot data generated from an Electric Imp Env Tail.

## Device

The Device code is taken directly from the Weather Station project and sends a table with readings from all of its sensors to the Agent every 5 minutes.

## Agent

The Agent does the following in a series of nested callbacks:

- Creates a publicly viewable plot.
- Registers a function to respond to device data messages.
    - This function generates a Plotly-recognized timestamp and calls the library's `post` method to append the device data to the plot at the current timestamp.
    - It then prints the Plotly API's response to the append command.
- Sets the title of the plot.
- Sets the x- and y-axis labels on the plot.
- Sets a custom style for the plot that includes marker shapes and colors.
- Adds a second y-axis to the right of the graph with a label and uses the axis to track two existing data traces.
- Prints the plot URL to the server logs.
