import argparse
import copy
import functools
import logging
import subprocess
import sys
import time 
import os
import configparser

from paramiko import SSHClient

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
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("sudo pkill http_server")
    for line in ssh_stdout:
        logging.info("Run server output: " + str(line))
    for line in ssh_stderr:
        logging.info("Run server error: " + str(line))
    ssh.close()
    time.sleep(20)

def run_server(server_time, server_threads):

    flag = True 
    while flag:
        flag = False
        cmd = "sudo ~/Synthetic-workload-client-conf/http_server {} {} &> ~/server_out & sleep 5; cat ~/server_out".format(server_threads, server_time)
        print(cmd)
        ssh = SSHClient()
        ssh.load_system_host_keys()
        ssh.connect(str("node1"))
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd)
        for line in ssh_stdout:
            print(line)
            logging.info("Run server output: " + str(line))
            if "bind failed: Address already in use" in line:
                flag = True
                break
            else:
                flag = False
        for line in ssh_stderr:
            print(line)
            logging.info("Run server error: " + str(line))
            if "bind failed: Address already in use" in line:
                flag = True
                break
            else:
                flag = False
    
    ssh.close()


def run_single_experiment(root_results_dir, name_prefix, server_time, client_threads, queries, num_threads_server, exec_time, iter):

    results_dir_path = os.path.join(root_results_dir, name_prefix)

    if not os.path.exists(results_dir_path):
        os.mkdir(results_dir_path)
    else:
        logging.info("Directory already exists: " + results_dir_path)

    print(results_dir_path)
    

    kill_server()
    run_server(server_time, num_threads_server)

    # do the measured run
    ssh = SSHClient()
    ssh.load_system_host_keys()
    ssh.connect("node0")
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("cd ~/Synthetic-workload-client-conf/wrk2/; ~/Synthetic-workload-client-conf/wrk2/wrk -D fixed \
    -t{} -c{} -d{} -R{} --latency http://node1:8080 &> ~/wrk_output; sleep 20; cat ~/wrk_output".format(client_threads, client_threads, exec_time, queries))
    ssh_stdout.channel.recv_exit_status()  # Wait for the command to finish
    ssh_stderr.channel.recv_exit_status()
    ssh.close()

    # for line in ssh_stdout:
    #     print(line)

    for line in ssh_stderr:
        logging.info("Run server error: " + str(line))
    
    # write statistics 
    synthetic_results_path_name = os.path.join(results_dir_path, 'latency_output')
    with open(synthetic_results_path_name, 'w') as fo:
        for l in ssh_stdout:
            fo.write(l +'\n')
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
        os.system('cd ~/Synthetic-workload-client-conf/client-conf-scripts/; ~/Synthetic-workload-client-conf/client-conf-scripts/set-client-configuration.sh main 1010110 node1 ~/Synthetic-workload-client-conf/client-conf-scripts/ node2,{}'.format(results_dir_path))
    else:
        logging.info("Wrong Server Configuration")

def configure_client_node(system_conf, root_result_dir):

    # Make client directory for configurations
    results_dir_path = os.path.join(root_result_dir, "client")

    if not os.path.exists(results_dir_path):
        os.mkdir(results_dir_path)
    else:
        logging.info("Directory already exists: " + results_dir_path)
    

    if system_conf['client'] == "HP":

        os.system("cd ~/Synthetic-workload-client-conf/client-conf-scripts/; ~/Synthetic-workload-client-conf/client-conf-scripts/set-client-configuration.sh main 0001111 node0 ~/Synthetic-workload-client-conf/client-conf-scripts/ node2,{}".format(results_dir_path))

    elif system_conf['client'] == "LP":
        
        os.system("cd ~/Synthetic-workload-client-conf/client-conf-scripts/; ~/Synthetic-workload-client-conf/client-conf-scripts/set-client-configuration.sh main 3101001 node0 ~/Synthetic-workload-client-conf/client-conf-scripts/ node2,{}".format(results_dir_path))

    else:
        logging.info("Wrong Client Configuration")

def run_multiple_experiments(root_results_dir, batch_name, system_conf, iter):
    
    # Make each configuration root dir
    result_dir="client={}-server={}".format(system_conf['client'], system_conf['server'])
    
    
    if not os.path.exists(root_results_dir):
        os.mkdir(root_results_dir)

    results_dir_path = os.path.join(root_results_dir, batch_name)
    
    if not os.path.exists(results_dir_path):
        os.mkdir(results_dir_path)
    
    subresults_dir_path = os.path.join(results_dir_path, result_dir)
    if not os.path.exists(subresults_dir_path):
        os.mkdir(subresults_dir_path)
    else:
        logging.info("Directory already exists: " + subresults_dir_path)
    
    # Configure Server Node
    configure_server_node(system_conf, subresults_dir_path)
    

    # Configure Client Node
    configure_client_node(system_conf, subresults_dir_path)

    service_time = [1, 10, 100, 1000, 10000]
    exec_time = 120
    num_threads_server = 0
    num_threads_client = [1,10]
    qps = [100, 1000, 10000, 100000]

    for server_time in service_time:
        for client_threads in num_threads_client:
            for queries in qps:
                print("irtaaaaaaaaaaaaaa\n")
                name_prefix = "service-time={}-client-threads={}-qps={}-{}".format(server_time, client_threads, queries,iter)
                num_threads_server = client_threads
                # Make experiment directory
                run_single_experiment(subresults_dir_path, name_prefix, server_time, client_threads, queries, num_threads_server, exec_time, iter)


def main(argv):

    system_confs = [
       {'client': 'HP',  'server': 'fixed'},
       {'client': 'LP',  'server': 'fixed'},
    ]

    logging.getLogger('').setLevel(logging.INFO)
    if len(argv) < 1:
        raise Exception("Experiment name is missing")
    batch_name = argv[0]
    for iter in range(0, 5):
        for system_conf in system_confs:
            run_multiple_experiments('/users/ganton12/data', batch_name, system_conf, iter)

if __name__ == '__main__':
    main(sys.argv[1:])