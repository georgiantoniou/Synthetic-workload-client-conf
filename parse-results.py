import os
import pandas as pd
import json
import statistics
import csv 
import sys
import math
import re
from itertools import combinations

#Need to Check confidence interval theory

qps_list = [100, 1000, 10000, 100000]
z=1.96 # from taming performance variability paper
# n=50

def print_all_metrics(stats_dir, overall_raw_measurements, overall_statistics, filename):

    header = ["exp_name","service_time", "client_threads", "qps", "metric", "avg", "median", "stdev", "cv", "ci-min", "ci-max"]
   
    for exp_name in overall_raw_measurements:
        for conf_list in overall_raw_measurements[exp_name]:
            for id,conf in enumerate(list(conf_list.keys())):
                for client_threads in overall_raw_measurements[exp_name][id][conf]:
                    for qps in qps_list:
                        for metric in overall_raw_measurements[exp_name][id][conf][client_threads][qps]:
                            size = len(overall_raw_measurements[exp_name][id][conf][client_threads][qps][metric])
                            break
                        break
                    break
                break
            break
        break
   
    for i in range(0,size):
        header.append("M" + str(i+1))
   
    filename = os.path.join(stats_dir, filename)
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=',',
                                quotechar='|', quoting=csv.QUOTE_MINIMAL)
        writer.writerow(header)

        for exp_name in overall_raw_measurements:
            for conf_list in overall_raw_measurements[exp_name]:
                for id,conf in enumerate(list(conf_list.keys())):
                    for client_threads in overall_statistics[exp_name][0][conf]:
                        print(overall_statistics[exp_name][0][conf])
                        for metric in overall_statistics[exp_name][0][conf][client_threads][qps_list[0]]:
                            for qps in qps_list:
                                row = []
                                row.append(exp_name)
                                row.append(conf)
                                row.append(client_threads)
                                row.append(qps)
                                row.append(metric)
                                row.append(overall_statistics[exp_name][0][conf][client_threads][qps][metric]["avg"])
                                row.append(overall_statistics[exp_name][0][conf][client_threads][qps][metric]["median"])
                                row.append(overall_statistics[exp_name][0][conf][client_threads][qps][metric]["stdev"])
                                row.append(overall_statistics[exp_name][0][conf][client_threads][qps][metric]["cv"])
                                row.append(overall_statistics[exp_name][0][conf][client_threads][qps][metric]["ci"]["min"])
                                row.append(overall_statistics[exp_name][0][conf][client_threads][qps][metric]["ci"]["max"])
                                for meas in overall_raw_measurements[exp_name][0][conf][client_threads][qps][metric]:
                                    row.append(meas)
                                
                                writer.writerow(row)

def print_residency_merged(stats_dir, overall_raw_measurements, overall_statistics, metric, filename):
    header = ["exp_name","configuration","qps", "metric", "C0", "C1", "C1E", "C6"]
      
    filename = os.path.join(stats_dir, filename)
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=',',
                                quotechar='|', quoting=csv.QUOTE_MINIMAL)
        writer.writerow(header)

        for exp_name in overall_raw_measurements:
            for conf_list in overall_raw_measurements[exp_name]:
                for id,conf in enumerate(list(conf_list.keys())):
                    for qps in qps_list:
                        if "C0-res" not in overall_statistics[exp_name][0][conf][qps]:
                            return
                        row = []
                        row.append(exp_name)
                        row.append(conf)
                        row.append(qps)
                        row.append(metric)
                        row.append(overall_statistics[exp_name][0][conf][qps]['C0-res']["avg"])
                        row.append(overall_statistics[exp_name][0][conf][qps]['C1-res']["avg"])
                        row.append(overall_statistics[exp_name][0][conf][qps]['C1E-res']["avg"])
                        row.append(overall_statistics[exp_name][0][conf][qps]['C6-res']["avg"])
                        writer.writerow(row)

def print_transition_merged(stats_dir, overall_raw_measurements, overall_statistics, metric, filename):
    
    header = ["exp_name","configuration","qps", "metric", "C0", "C1", "C1E", "C6"]

    filename = os.path.join(stats_dir, filename)
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=',',
                                quotechar='|', quoting=csv.QUOTE_MINIMAL)
        writer.writerow(header)

        for exp_name in overall_raw_measurements:
            for conf_list in overall_raw_measurements[exp_name]:
                for id,conf in enumerate(list(conf_list.keys())):
                    for qps in qps_list:
                        if "C0-tr" not in overall_statistics[exp_name][0][conf][qps]:
                            return
                        row = []
                        row.append(exp_name)
                        row.append(conf)
                        row.append(qps)
                        row.append(metric)
                        row.append(overall_statistics[exp_name][0][conf][qps]['C0-tr']["avg"])
                        row.append(overall_statistics[exp_name][0][conf][qps]['C1-tr']["avg"])
                        row.append(overall_statistics[exp_name][0][conf][qps]['C1E-tr']["avg"])
                        row.append(overall_statistics[exp_name][0][conf][qps]['C6-tr']["avg"])
                        writer.writerow(row)

def print_single_metric(stats_dir, overall_raw_measurements, overall_statistics, metric, filename):

    header = ["exp_name","configuration","qps", "metric", "avg", "median", "stdev", "cv", "ci-min", "ci-max"]
   
    for exp_name in overall_raw_measurements:
        for conf_list in overall_raw_measurements[exp_name]:
            for id,conf in enumerate(list(conf_list.keys())):
                for qps in qps_list:
                    if not "C0-res" in overall_raw_measurements[exp_name][0][conf][qps]:
                        return
                    size = len(overall_raw_measurements[exp_name][0][conf][qps][metric])
                break
            break
        break
    
    for i in range(0,size):
        header.append("M" + str(i+1))
   
    filename = os.path.join(stats_dir, filename)
    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile, delimiter=',',
                                quotechar='|', quoting=csv.QUOTE_MINIMAL)
        writer.writerow(header)

        for exp_name in overall_raw_measurements:
            for conf_list in overall_raw_measurements[exp_name]:
                for id,conf in enumerate(list(conf_list.keys())):
                    for qps in qps_list:
                        row = []
                        row.append(exp_name)
                        row.append(conf)
                        row.append(qps)
                        row.append(metric)
                        row.append(overall_statistics[exp_name][0][conf][qps][metric]["avg"])
                        row.append(overall_statistics[exp_name][0][conf][qps][metric]["median"])
                        row.append(overall_statistics[exp_name][0][conf][qps][metric]["stdev"])
                        row.append(overall_statistics[exp_name][0][conf][qps][metric]["cv"])
                        row.append(overall_statistics[exp_name][0][conf][qps][metric]["ci"]["min"])
                        row.append(overall_statistics[exp_name][0][conf][qps][metric]["ci"]["max"])
                        for meas in overall_raw_measurements[exp_name][0][conf][qps][metric]:
                            row.append(meas)
                        
                        writer.writerow(row)

def confidence_interval_mean (metric_measurements):
    temp_list  = metric_measurements.copy()
    temp_list.sort()
    n = len(temp_list)
    
    min_i = math.floor((n-z*math.sqrt(n)) / 2)
    max_i = math.ceil(1 + (n+z*math.sqrt(n)) / 2) 
    return temp_list[min_i-1], temp_list[max_i-1]

def coefficient_of_variation(metric_measurements):
    return statistics.stdev(metric_measurements) / statistics.mean(metric_measurements)

def standard_deviation(metric_measurements):
    return statistics.stdev(metric_measurements)

def median(metric_measurements):
    return statistics.median(metric_measurements)

def average(metric_measurements):
    return statistics.mean(metric_measurements)

def average_ignore_zeros(metric_measurements):
    return statistics.mean([i for i in metric_measurements if i!=0] or [0])

def calculate_speedup_stats_single_instance(instance_stats, first_item, second_item):

    metrics = ['avg','99th']
    for qps in first_item:
        instance_stats[qps] = {}
        for metric in metrics:
           
            # measure items in 1 and 2
            len1 = len(first_item[qps][metric])
            len2 = len(second_item[qps][metric])
            if len1 >= len2:
                num_elements = len2
            else:
                num_elements = len1

            # measure x speedups 1 - x1/x2 for both avg and 99th tail latency
            instance_stats[qps][str(metric) + "-speedup"] = []
            for i in range(0,num_elements):
                instance_stats[qps][str(metric) + "-speedup"].append(first_item[qps][metric][i] / second_item[qps][metric][i])
               
            # measure CI for avg
            instance_stats[qps][str(metric) + "-speedup" + "-ci-min"], instance_stats[qps][str(metric) + "-speedup" + "-ci-max"] = confidence_interval_mean(instance_stats[qps][str(metric) + "-speedup"])
            
def calculate_stats_single_instance(instance_stats, instance_raw_measurements, conf):
    for client_threads in instance_raw_measurements[conf]:
        instance_stats[client_threads] = {}
        for qps in instance_raw_measurements[conf][client_threads]:
            instance_stats[client_threads][qps] = {}
            for metric in instance_raw_measurements[conf][client_threads][qps]:
                if instance_raw_measurements[conf][client_threads][qps][metric]:
                    instance_stats[client_threads][qps][metric] = {}
                    #calculate statistics   
                    instance_stats[client_threads][qps][metric]['avg'] = average(instance_raw_measurements[conf][client_threads][qps][metric])
                    instance_stats[client_threads][qps][metric]['median'] = median(instance_raw_measurements[conf][client_threads][qps][metric])
                    instance_stats[client_threads][qps][metric]['stdev'] = standard_deviation(instance_raw_measurements[conf][client_threads][qps][metric])
                    if instance_stats[client_threads][qps][metric]['median'] > 0:
                        instance_stats[client_threads][qps][metric]['cv'] = coefficient_of_variation(instance_raw_measurements[conf][client_threads][qps][metric])
                    else:
                        instance_stats[client_threads][qps][metric]['cv'] = 0
                    instance_stats[client_threads][qps][metric]['ci'] = {}
                    instance_stats[client_threads][qps][metric]['ci']['min'] = 0
                    instance_stats[client_threads][qps][metric]['ci']['max'] = 0
                    # instance_stats[client_threads][qps][metric]['ci']['min'], instance_stats[client_threads][qps][metric]['ci']['max'] = confidence_interval_mean(instance_raw_measurements[conf][client_threads][qps][metric])
                else:
                    instance_stats[client_threads][qps][metric] = {}
                    instance_stats[client_threads][qps][metric]['avg'] = 0
                    instance_stats[client_threads][qps][metric]['median'] = 0
                    instance_stats[client_threads][qps][metric]['stdev'] = 0
                    instance_stats[client_threads][qps][metric]['cv'] = 0
                    instance_stats[client_threads][qps][metric]['ci'] = {}
                    instance_stats[client_threads][qps][metric]['ci']['min'] = 0
                    instance_stats[client_threads][qps][metric]['ci']['max'] = 0


def calculate_stats_multiple_instances(exp_name,overall_raw_measurements):

    instances_stats = {}
    for ind,instance in enumerate(overall_raw_measurements[exp_name]):
        for conf in overall_raw_measurements[exp_name][ind]:
            instances_stats[conf] = {}
            calculate_stats_single_instance(instances_stats[conf], overall_raw_measurements[exp_name][ind], conf)
   
    return instances_stats

def derive_datatype(datastr):
    try:
        return type(ast.literal_eval(datastr))
    except:
        return type("")

       

def add_metric_to_dict(stats_dict, metric_name, metric_value):
    head = metric_name.split('.')[0]
    tail = metric_name.split('.')[1:]
    if tail:
        stats_dict = stats_dict.setdefault(head, {})
        add_metric_to_dict(stats_dict, '.'.join(tail), metric_value)
    else:
        stats_dict[head] = metric_value


def separate_digits_and_nondigits(input_string):
    index = len(input_string) - 1

    # Find the first digit from the end
    while index >= 0 and not input_string[index].isdigit():
        index -= 1

    # Slice the string into digits and non-digits parts
    digits_str = input_string[:index + 1]
    non_digits_str = input_string[index + 1:]

    return digits_str, non_digits_str


def parse_client_time(client_stats_file):
    stats = {}  
    with open(client_stats_file, 'r') as f:
        flag = False
        for l in f:
            if flag:
                if "Latency" in l:
                    digits_str, non_digits_str=separate_digits_and_nondigits(l.split()[1])
                    
                    if non_digits_str=="us":
                        stats['avg'] = float(digits_str)/1000
                    elif non_digits_str=="s":
                        stats['avg'] = float(digits_str) * 1000
                    else:
                        stats['avg'] = float(digits_str)

                    digits_str, non_digits_str=separate_digits_and_nondigits(l.split()[3])
                    if non_digits_str=="us":
                        stats['99th'] = float(digits_str)/1000
                    elif non_digits_str=="s":
                        stats['99th'] = float(digits_str) * 1000
                    else:
                        stats['99th'] = float(digits_str)
                    break
                    
            if "Thread Stats" in l:
                flag = True
                continue
                                
    return stats


def parse_client_throughput(client_stats_file):
    
    with open(client_stats_file, 'r') as f:
        flag = False
        for l in f:
            if flag:
                if next(f).strip() and "Latency" not in next(f):
                    digits_str, non_digits_str=separate_digits_and_nondigits(next(f).split()[1])
                    if non_digits_str=="k":
                        return float(digits_str)*1000
                    else:
                        return float(digits_str)
            if "Thread Stats" in l:
                flag = True
                continue
                

def parse_single_instance_stats(stats,stats_dir, qps):
    
    run = int(stats_dir.split("-")[-1])
   
    if "throughput" not in stats:
        stats['throughput'] = []
        stats['avg'] = []
        stats['99th'] = []
    
    # Check if client turbostat in files parse turbostat as well with the rest   

    client_stats_file = os.path.join(stats_dir, 'latency_output')
    if os.path.exists(client_stats_file):
        qps_temp = parse_client_throughput(client_stats_file)
        stats['throughput'].insert(run, qps_temp) 

        client_time_stats = {}
        client_time_stats = parse_client_time(client_stats_file)
        stats['avg'].insert(run,client_time_stats['avg'])
        stats['99th'].insert(run,client_time_stats['99th'])
   

def parse_multiple_instances_stats(exp_dir, pattern='.*'):
    
    instances_raw_measurements = {}
    exp_name = exp_dir.split("/")[-1]
    
    dirs = list(os.listdir(exp_dir))
    dirs.sort()

    for conf in dirs:   
        
        instance_dir = os.path.join(exp_dir, conf)
        
        #check if the configuration is a directory and not just the directory client and server

        if not os.path.isdir(instance_dir) or conf == "client" or conf == "server":
            continue

        instance_name = conf[:conf.rfind('-')]
        print(instance_name)
        qps = int(instance_name.split("=")[-1])
        instance_name = instance_name[:instance_name.rfind('-')]
        client_threads = int(instance_name.split("=")[-1])
        instance_name = instance_name[:instance_name.rfind('-')]
        instance_name = instance_name[:instance_name.rfind('-')]
        service_time = int(instance_name.split("=")[-1])

        if not os.path.isdir(exp_dir):
            continue

        if service_time not in instances_raw_measurements:
            instances_raw_measurements[service_time] = {}
        if client_threads not in instances_raw_measurements[service_time]:
            instances_raw_measurements[service_time][client_threads] = {}
        if qps not in instances_raw_measurements[service_time][client_threads]:
            instances_raw_measurements[service_time][client_threads][qps] = {}
       
        parse_single_instance_stats(instances_raw_measurements[service_time][client_threads][qps],instance_dir, qps)
        
    return instances_raw_measurements

def parse_multiple_exp_stats(stats_dir, pattern='.*'):

    # extract data
    overall_raw_measurements = {}
    for f in os.listdir(stats_dir):
        exp_dir = os.path.join(stats_dir, f)
        if not os.path.isdir(exp_dir):
            continue

        #get configuration for experiment and parse raw data 
        overall_raw_measurements.setdefault(f, []).append(parse_multiple_instances_stats(exp_dir))
    
    #parse statistics
    overall_statistics = {}
    for exp_name in overall_raw_measurements:
        overall_statistics.setdefault(exp_name, []).append(calculate_stats_multiple_instances(exp_name,overall_raw_measurements))


    print_all_metrics(stats_dir, overall_raw_measurements, overall_statistics, "all-metrics.csv") 
    # print_single_metric(stats_dir, overall_raw_measurements, overall_statistics, "throughput", "overall_throughput_time.csv")
    # print_single_metric(stats_dir, overall_raw_measurements, overall_statistics, "avg", "overall_average_time.csv")
    # print_single_metric(stats_dir, overall_raw_measurements, overall_statistics, "99th", "overall_99th_time.csv")
    

    return overall_raw_measurements


def main(argv):
    stats_root_dir = argv[1]
    stats = parse_multiple_exp_stats(stats_root_dir)
        
if __name__ == '__main__':
    main(sys.argv)