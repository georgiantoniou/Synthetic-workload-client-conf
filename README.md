# Summary

The aim of this project is to investigate what is the impact of the client side hardware configuration on the end to end response time of an application. Specifically, we do a sensitivity analysis that shows how client side affects the end to end response time while we increase the response time from microseconds to milliseconds. 

To achieve this we implement a simple http multithreaded server in c. The server takes two parameters the number of threads and the sleep time. The sleep time represents the increasing response time of a request. We use wrk2 http workload generator to generate the load.

# Install dependencies


# Compile source code


# Configure Machines


# Run experiments
