import argparse
import copy
import functools
import logging
import subprocess
import sys
import time 
import os
import configparser

import common 

log = logging.getLogger(__name__)


def exec_command(cmd):
    logging.info(cmd)
    result = subprocess.run(cmd.split(), stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    for l in result.stdout.decode('utf-8').splitlines():
        logging.info(l)
    for l in result.stderr.decode('utf-8').splitlines():
        logging.info(l)
    return result.stdout.decode('utf-8').splitlines()

def kill_server():

    ssh = SSHClient()
    ssh.load_system_host_keys()
    ssh.connect(str("node1"))
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("pkill http_server")
    logging.info("Kill server output: " + ssh_stdin + ssh_stdout + ssh_stderr)
    ssh.close()

def run_server(server_time, server_threads):

    cmd = "~/Synthetic-workload-client-conf/server {} {} &".format(server_threads, server_time)
    ssh = SSHClient()
    ssh.load_system_host_keys()
    ssh.connect(str("node1"))
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd)
    logging.info("Run server output: " + ssh_stdin + ssh_stdout + ssh_stderr)
    ssh.close()


def run_single_experiment(root_results_dir, name_prefix, server_time, client_threads, queries, num_threads_server, exec_time, iter):

    results_dir_path = os.path.join(root_results_dir, name_prefix)

    kill_server()
    run_server(server_time, num_threads_server)
   
    # do the measured run
    ssh = SSHClient()
    ssh.load_system_host_keys()
    ssh.connect("node0")
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("~/Synthetic-workload-client-conf/wrk2/wrk -D fixed \
    -t{} -c{} -d{} -R{} http://node1:8080".format(client_threads, client_threads, exec_time, queries))
    ssh.close()
    logging.info("Run client output: " + ssh_stdin + ssh_stdout + ssh_stderr)

    # write statistics 
    synthetic_results_path_name = os.path.join(results_dir_path, 'latency_output')
    with open(synthetic_results_path_name, 'w') as fo:
        for l in ssh_stdout:
            fo.write(l+'\n')

    # cleanup
    kill_server()


def configure_server_node(system_conf, root_result_dir):

    # Make server directory for configurations
    results_dir_path = os.path.join(root_result_dir, "server")

    if not os.path.exists(results_dir_path):
        os.mkdir(results_dir_path)
    else:
        logging.info("Directory already exists: " + results_dir_path)


    if system_conf['server'] == "fixed":
        exec_command("~/Synthetic-workload-client-conf/client-conf-scripts/set-client-configuration.sh main 1010110 node1 ~/Synthetic-workload-client-conf/client-conf-scripts/ node2,~/data/{}/server".format(root_result_dir))
        
    else:
        
        logging.info("Wrong Server Configuration")
        exit()

def configure_client_node(system_conf, root_result_dir):

    # Make client directory for configurations
    results_dir_path = os.path.join(root_result_dir, "client")

    if not os.path.exists(results_dir_path):
        os.mkdir(results_dir_path)
    else:
        logging.info("Directory already exists: " + results_dir_path)
    

    if system_conf['server'] == "HP":

        exec_command("~/Synthetic-workload-client-conf/client-conf-scripts/set-client-configuration.sh main 0001111 node0 ~/Synthetic-workload-client-conf/client-conf-scripts/ node2,~/data/{}/client".format(root_result_dir))

    elif system_conf['server'] == "LP":
        
        exec_command("~/Synthetic-workload-client-conf/client-conf-scripts/set-client-configuration.sh main 3101001 node0 ~/Synthetic-workload-client-conf/client-conf-scripts/ node2,~/data/{}/client".format(root_result_dir))

    else:

        logging.info("Wrong Client Configuration")
        exit()

def run_multiple_experiments(root_results_dir, batch_name, system_conf, batch_conf, iter):
    
    # Make each configuration root dir
    result_dir="client={}-server={}".format(system_conf['client'], system_conf['server'])
    results_dir_path = os.path.join(root_results_dir, result_dir)

    if not os.path.exists(results_dir_path):
        os.mkdir(results_dir_path)
    else:
        logging.info("Directory already exists: " + results_dir_path)
    

    # Configure Server Node
    configure_server_node(system_conf, results_dir_path)
    
    # Configure Client Node
    configure_client_node(system_conf, results_dir_path)

    service_time = [1, 10, 100, 1000, 10000]
    exec_time = 120
    num_threads_server = 10
    num_threads_client = [1, 10, 40]
    qps = [10, 100, 1000, 10000]

    for server_time in service_time:
        for client_threads in num_threads_client:
            for queries in qps:
                name_prefix = "service-time={}-client-threads={}-qps={}-{}".format(server_time, client_threads, queries,iter)

                # Make experiment directory
                run_single_experiment(results_dir_path, name_prefix, server_time, client_threads, queries, num_threads_server, exec_time, iter)


def main(argv):

    system_confs = [
       {'client': 'HP',  'server': 'fixed'},
       {'client': 'LP',  'server': 'fixed'},
    ]

    logging.getLogger('').setLevel(logging.INFO)
    if len(argv) < 1:
        raise Exception("Experiment name is missing")
    batch_name = argv[0]
    for iter in range(0, 10):
        for system_conf in system_confs:
            run_multiple_experiments('/users/ganton12/data', batch_name, system_conf, iter)

if __name__ == '__main__':
    main(sys.argv[1:])