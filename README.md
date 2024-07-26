# Summary

The aim of this project is to investigate what is the impact of the client side hardware configuration on the end to end response time of an application. Specifically, we do a sensitivity analysis that shows how client side affects the end to end response time while we increase the response time from microseconds to milliseconds. 

To achieve this we implement a simple http multithreaded server in c. The server takes two parameters the number of threads and the sleep time. The sleep time represents the increasing response time of a request. We use wrk2 http workload generator to generate the load.

# Install dependencies

```
sudo apt-get update
sudo apt-get install -y libssl-dev libz-dev luarocks make 
sudo luarocks install luasocket
sudo apt install python3-pip
pip3 install --upgrade setuptools
sudo apt-get install python3.6-dev libmysqlclient-dev libpcap-dev libpq-dev
pip3 install --upgrade pip3
pip3 install --upgrade pip
pip3 install paramiko
```

# Compile source code for http server

```
gcc -o http_server http_server.c -lpthread
```

# Compile source code for wrk2
```
cd ~/Synthetic-workload-client-conf/wrk2
make
sudo make install
```

# Configure Machines


# Run experiments

Advised client (threads x connections) to match the server threads
```
sudo ./http_server thread_num wait_time_us

```