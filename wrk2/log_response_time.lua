local socket = require("socket")  -- Import the LuaSocket library

-- Initialize a unique log file for each thread
setup = function(thread)
    -- Initialize thread-specific variables
    thread:set("id", thread:get("id") or math.random(100000)) -- Assign a unique ID for each thread
end

-- This function will be called before each request is sent
request = function()
    -- Capture the timestamp when the request is sent (before sending the request)
    local send_timestamp = socket.gettime()  -- This provides high-resolution time in seconds
    wrk.headers["X-Send-Timestamp"] = send_timestamp  -- Send timestamp in the header (for debugging)
    return wrk.format(nil, nil)
end

-- Initialize the log file for each thread
init = function(args)
    local log_file_name = "response_times_thread_" .. wrk.thread:get("id") .. ".txt"
    file = io.open(log_file_name, "w")
    file:write("Request Send Timestamp, Response Receive Timestamp, Response Time (us)\n")
end

-- This function will be called for every response
response = function(status, headers, body)
    -- Get the timestamp when the response is received
    local receive_timestamp = socket.gettime()  -- High-resolution time for response receive

    -- Get the timestamp when the request was sent (from the header)
    local send_timestamp = tonumber(wrk.headers["X-Send-Timestamp"])

    -- Calculate the response time (in microseconds)
    if send_timestamp then
        local response_time = (receive_timestamp - send_timestamp) * 1000000  -- Convert to microseconds
        -- Log the timestamps and the response time
        file:write(string.format("%.6f, %.6f, %.3f\n", send_timestamp, receive_timestamp, response_time))
    else
        -- If send_timestamp is missing, log an error
        file:write("ERROR, ERROR, ERROR\n")
    end
end

-- Close the file at the end of the test
done = function(summary, latency, requests)
    if file then
        file:close()
    end
end