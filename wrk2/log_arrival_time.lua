local socket = require("socket")  -- Import the LuaSocket library
local file -- Declare file variable for thread-specific logging
local threads = {}

-- Called when a new thread is created
function setup(thread)
    local id = #threads + 1 -- Assign a unique ID to each thread
    thread:set("id", id) -- Pass the ID to the thread
    table.insert(threads, thread)
end

-- Called once per thread to initialize resources
function init(args)
    -- Open a thread-specific file for appending timestamps
    file = io.open("timestamps_thread_" .. id .. ".log", "a")
    if not file then
        error("Failed to open file for logging in thread " .. id)
    end
end

-- Called for each request
function request()
    -- Capture a timestamp for the request
    local ts = socket.gettime() -- Timestamp in seconds since the epoch
    file:write(ts .. "\n")
    file:flush() -- Ensure the timestamp is written immediately
    return wrk.format("GET", "/") -- Replace with your desired request
end

-- Called once when the script ends
function done(summary, latency, requests)
    if file then
        file:close() -- Close the file to finalize logging
    end
end