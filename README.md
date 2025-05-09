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
sudo apt install -y libgsl-dev
sudo apt install -y sysstat

# Systemtap dependencies
sudo apt install systemtap
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C8CAB6595FDFF622 
codename=$(lsb_release -c | awk  '{print $2}')
sudo tee /etc/apt/sources.list.d/ddebs.list << EOF
deb http://ddebs.ubuntu.com/ ${codename}      main restricted universe multiverse
deb http://ddebs.ubuntu.com/ ${codename}-security main restricted universe multiverse
deb http://ddebs.ubuntu.com/ ${codename}-updates  main restricted universe multiverse
deb http://ddebs.ubuntu.com/ ${codename}-proposed main restricted universe multiverse
EOF

sudo apt-get update
sudo apt-get install linux-image-$(uname -r)-dbgsym

# Cloudlab 18.04 ubuntu dependencies for parser script

sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install python3.8

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3.8 get-pip.py

python3.8 -m pip install pandas
python3.8 -m pip install scipy
python3.8 -m pip install statsmodels
```

# Compile source code for http server

```
gcc -o http_server http_server.c -lpthread
```

# Compile source code for http server with exponential response time
```
gcc -o http_server_exp http_server_exp.c -lgsl -lgslcblas -lm -lpthread
```

# Compile source code for http server with exponential response time and server side service time statistics
```
gcc -o http_server_exp_timer http_server_exp_timer.c -lgsl -lgslcblas -lm -lpthread
```

# Compile source code for wrk2
```
cd ~/Synthetic-workload-client-conf/wrk2
make
sudo make install
```
# Run wrk2 code
```
./wrk2/wrk -t1 -D exp -c1 -d20s -R10 http://node0:8080
```
One thread, one connection, exponential interarrival time, 20 second duration (10 of which for calibration) 10 QPS server listening at node1 port 8080.

# Configure Machines

## To disable coalescing
```
# Need to reset at each reboot
sudo ethtool -c enp94s0f1
sudo ethtool -C enp94s0f1 adaptive-rx off adaptive-tx off
sudo ethtool -C enp94s0f1 rx-usecs 0 tx-usecs 0
sudo ethtool -c enp94s0f1

```

# Run experiments

Advised client (threads x connections) to match the server threads
```
sudo ./http_server thread_num wait_time_us

```