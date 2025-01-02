local file -- Declare file variable at the top for global access

-- Called once when the script starts
function init(args)
    -- Open the file for appending timestamps
    file = io.open("timestamps_" .. id .. ".log", "a")
    if not file then
        error("Failed to open file for logging")
    end
end

function setup(thread)
    thread:set("id", #threads + 1)
end

-- Called for each request
function request()
    -- Capture a timestamp for the request
    local ts = os.time()
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