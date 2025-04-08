import os
import pandas as pd
import json
import statistics
import csv 
import sys
import math
import re
from itertools import combinations

import numpy as np

from scipy import stats
from scipy.stats import anderson
import statsmodels.api as sm


statss = {}
warmup=20
queriespersecond=10
cores=40

def get_exp(name):
    return name.split("/")[-1]

def print_idle_time_systemtap(expstats, dir):
    print("irtaaaaaa")
    path = os.path.join(dir, "results")
    print(path)

    os.makedirs(path, exist_ok=True)  # Create all intermediate directories if they don't exist
    
    idle_tres = os.path.join(path, "stap-idle-tres.csv")
    idle_tr = os.path.join(path, "stap-idle-tr.csv")

    

    tres = {}
    tr = {}

    temp=0
    for key in expstats[0].keys():
        temp = key
        break
    
    max_runs= (max([int(k) for k in expstats[0][temp]['stap-idle'].keys()])) + 1

    if not expstats[0][temp]['stap-idle'][0]:
        return

    label1=[]
    label2=[]
    for key in expstats[0].keys():
        for i in range(max_runs):
            label1.append(key)
            label2.append(i)
    
    max_lines=len([line for key in expstats[0].keys() for lines in expstats[0][key]['stap-idle'] for line in expstats[0][key]['stap-idle'][lines]])
   
    print(idle_tr)
    print(idle_tres)

    to_print_tr={}
    to_print_tres={}
    to_print_tr['C0']=[]
    to_print_tr['C0-idle']=[]
    to_print_tr['C1']=[]
    to_print_tr['C1E']=[]
    to_print_tr['C6']=[]

    to_print_tres['C0']=[]
    to_print_tres['C0-idle']=[]
    to_print_tres['C1']=[]
    to_print_tres['C1E']=[]
    to_print_tres['C6']=[]

    with open(idle_tr, 'w', newline='') as csvfile:
       
        writer = csv.writer(csvfile)

        
        # Write the header row (QPS values as columns)
        writer.writerow(label1)
        writer.writerow(label2)
        # Write the data rows (align values by adding empty strings for shorter lists)
        
        for qps in expstats[0]:
            tres['C0']=0
            tres['C0-idle']=0
            tres['C1']=0
            tres['C1E']=0
            tres['C6']=0

            tr['C0']=0
            tr['C0-idle']=0
            tr['C1']=0
            tr['C1E']=0
            tr['C6']=0
            for run in expstats[0][qps]['stap-idle']:
                tres['C0']=0
                tres['C0-idle']=0
                tres['C1']=0
                tres['C1E']=0
                tres['C6']=0

                tr['C0']=0
                tr['C0-idle']=0
                tr['C1']=0
                tr['C1E']=0
                tr['C6']=0
                duration = (int(expstats[0][qps]['stap-idle'][run]['end_ts']) - int(expstats[0][qps]['stap-idle'][run]['start_ts']))/1000
                for meas in expstats[0][qps]['stap-idle'][run]['0']:
                    if int(meas) > 600:
                        tr['C6'] = tr['C6'] + int(meas)
                    elif int(meas) > 20:
                        tr['C1E'] = tr['C1E'] + int(meas)
                    elif int(meas) > 2:
                            tr['C1'] = tr['C1'] + int(meas)
                    else:
                            tr['C0-idle'] = tr['C0-idle'] + int(meas)

                    if int(meas) > 733:
                        tres['C6'] = tres['C6'] + int(meas)
                    elif int(meas) > 30:
                        tres['C1E'] = tres['C1E'] + int(meas)
                    elif int(meas) > 4:
                            tres['C1'] = tres['C1'] + int(meas)
                    else:
                            tres['C0-idle'] = tres['C0-idle'] + int(meas)
                to_print_tr['C6'].append(tr['C6']/duration)
                to_print_tr['C1E'].append(tr['C1E']/duration)
                to_print_tr['C1'].append(tr['C1']/duration)
                to_print_tr['C0-idle'].append(tr['C0-idle']/duration)
                to_print_tr['C0'].append(1 - tr['C6']/duration - tr['C1E']/duration - tr['C1']/duration - tr['C0-idle']/duration )

                to_print_tres['C6'].append(tres['C6']/duration)
                to_print_tres['C1E'].append(tres['C1E']/duration)
                to_print_tres['C1'].append(tres['C1']/duration)
                to_print_tres['C0-idle'].append(tres['C0-idle']/duration)
                to_print_tres['C0'].append(1 - tres['C6']/duration - tres['C1E']/duration - tres['C1']/duration - tres['C0-idle']/duration )

        states = ['C0', 'C0-idle', 'C1', 'C1E', 'C6']
        for state in states:
            print(state)
            row=[]
            for sample in to_print_tr[state]:
                row.append(float(sample))
            writer.writerow(row)   

    with open(idle_tres, 'w', newline='') as csvfile:  
        writer = csv.writer(csvfile)
        states = ['C0', 'C0-idle', 'C1', 'C1E', 'C6']
        for state in states:
            row=[]
            for sample in to_print_tres[state]:
                row.append(float(sample))
            writer.writerow(row)     
    print("efiaaaaaaaa")

def print_server_timer(expstats, dir):
    path = os.path.join(dir, "results")

    os.makedirs(path, exist_ok=True)  # Create all intermediate directories if they don't exist
    
    server_actual_timer_file = os.path.join(path, "serveractualtimer.csv")
    server_exp_timer_file = os.path.join(path, "serverexptimer.csv")

    temp=0
    for key in expstats[0].keys():
        temp = key
        break
    max_runs= (max([int(k) for k in expstats[0][temp]['server-timer-actual'].keys()])) + 1

    label1=[]
    label2=[]
    for key in expstats[0].keys():
        for i in range(max_runs):
            label1.append(key)
            label2.append(i)
    
    max_lines=len([line for key in expstats[0].keys() for lines in expstats[0][key]['server-timer-actual'] for line in expstats[0][key]['server-timer-actual'][lines]])
   
   
    print(server_actual_timer_file)
    
    # Write the dictionary to the CSV file
    with open(server_actual_timer_file, 'w', newline='') as csvfile:
       
        writer = csv.writer(csvfile)

        
        # Write the header row (QPS values as columns)
        writer.writerow(label1)
        writer.writerow(label2)
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_lines):
            row=[]
            for qps in expstats[0]:
                for run in expstats[0][qps]['server-timer-actual']:

                    if i < len(expstats[0][qps]['server-timer-actual'][run]):
                        row.append(float(expstats[0][qps]['server-timer-actual'][run][i])*1e6)
                    else:
                        row.append("")
            writer.writerow(row)   

    all_qq_data = []
    # remove the first qps*warmup queries 
    # Check whether it passes the cramer von misses test for exponential distribution
    percentiles = [25, 50, 75, 90, 95]
    for qps in expstats[0]:
        for run in expstats[0][qps]['server-timer-actual']:
            temp=expstats[0][qps]['server-timer-actual'][run]
            # remove warmed up queries from temp
            if temp:
                for i in range(warmup*queriespersecond):
                    temp.pop(0)
            for i in range(5):    
                
                if not temp:
                    continue

                
                percentile_to_remove_upper = 100 - i*5
                percentile_to_remove_lower = i*5

                # Step 1: Calculate the percentile value and filter the data
                if i:
                
                    threshold_value = np.percentile(temp, percentile_to_remove_upper)
                    filtered_data = [x for x in temp if x <= threshold_value]
                    
                    threshold_value = np.percentile(temp, percentile_to_remove_lower)
                    filtered_data_final = [x for x in filtered_data if x >= threshold_value]
                                    
                    # j = min(filtered_data_final)
                    # adjusted_values = [float(x) - float(j) for x in filtered_data_final]
                    adjusted_values=filtered_data_final

                else:
                    # j = min(temp)
                    # adjusted_values = [float(x) - float(j) for x in temp]
                    adjusted_values=temp
                
                # Step 1: Estimate the rate parameter (lambda) for the exponential distribution
                lambda_hat = 1 / np.mean(adjusted_values)

                # Step 2: Compute theoretical quantiles for the exponential distribution
                percentiles = [25, 50, 75, 90, 95]
                theoretical_quantiles = np.percentile(np.random.exponential(scale=1/lambda_hat, size=len(adjusted_values)), percentiles)

                # Step 3: Compute sample quantiles for your data
                sample_quantiles = np.percentile(adjusted_values, percentiles)

                # Step 4: Combine both theoretical and sample quantiles
                qq_data = list(zip(percentiles, theoretical_quantiles, sample_quantiles))

                temp2 = np.random.exponential(scale=1/lambda_hat, size=len(adjusted_values))
                # res = stats.cramervonmises(temp, "expon")
                res = stats.cramervonmises_2samp(np.array(adjusted_values), temp2)
                loc, scale = stats.expon.fit(adjusted_values)
                res2 = stats.cramervonmises(adjusted_values, 'expon', args=(loc, scale))

                # Add run index to each row (to distinguish runs in the CSV)
                for perc, theo, samp in qq_data:
                    all_qq_data.append([qps, run, percentile_to_remove_upper, perc, theo, samp, res2.pvalue, res.pvalue])
                

                # # Perform the Anderson-Darling test
                # ad_stat, critical_values, sig_level = anderson(adjusted_values, dist='expon')
                # print(ad_stat)
                # print(critical_values)
                # print(sig_level)
        
    # Step 5: Write the results to a CSV file
    output_file = os.path.join(path, "all_qq.csv")
    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        # Write header
        writer.writerow(["Lambda", "Run", "Percentile to Remove", "Percentile", "Theoretical Quantile", "Sample Quantile", "P value 1 sample", "P value 2 sample"])

        # Write all Q-Q data
        for row in all_qq_data:
            writer.writerow(row)
                
    
    # Write the dictionary to the CSV file
    with open(server_exp_timer_file, 'w', newline='') as csvfile:
       
        writer = csv.writer(csvfile)

        
        # Write the header row (QPS values as columns)
        writer.writerow(label1)
        writer.writerow(label2)
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_lines):
            row=[]
            for qps in expstats[0]:
                for run in expstats[0][qps]['server-timer-exp']:

                    if i < len(expstats[0][qps]['server-timer-exp'][run]):
                        row.append(float(expstats[0][qps]['server-timer-exp'][run][i])*1e6)
                    else:
                        row.append("")
            writer.writerow(row) 

def print_response(expstats, dir):
    
    path = os.path.join(dir, "results")    
    arrival_file = os.path.join(path, "response.csv")
    
    temp=0
    for key in expstats[0].keys():
        temp = key
        break
    max_runs= (max([int(k) for k in expstats[0][temp]['resp'].keys()])) + 1

    label1=[]
    label2=[]
    for key in expstats[0].keys():
        for i in range(max_runs):
            label1.append(key)
            label2.append(i)
   
    max_lines=len([line for key in expstats[0].keys() for lines in expstats[0][key]['resp'] for line in expstats[0][key]['resp'][lines]])
   
    # Write the dictionary to the CSV file
    with open(arrival_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        
        # Write the header row (QPS values as columns)
        writer.writerow(label1)
        writer.writerow(label2)
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_lines):
            row=[]
            for qps in expstats[0]:
                for run in expstats[0][qps]['resp']:

                    if i < len(expstats[0][qps]['resp'][run]):
                        row.append(expstats[0][qps]['resp'][run][i])
                    else:
                        row.append("")
            writer.writerow(row)
    
    all_qq_data = []
    # Check whether it passes the cramer von misses test for exponential distribution
    percentiles = [25, 50, 75, 90, 95]
    for qps in expstats[0]:
        for run in expstats[0][qps]['resp']:
            temp=expstats[0][qps]['resp'][run]
            for i in range(5):    
                
                if not temp:
                    return
                percentile_to_remove_upper = 100 - i*5
                percentile_to_remove_lower = i*5

                # Step 1: Calculate the percentile value and filter the data
                if i:
                
                    threshold_value = np.percentile(temp, percentile_to_remove_upper)
                    filtered_data = [x for x in temp if x <= threshold_value]
                    
                    threshold_value = np.percentile(temp, percentile_to_remove_lower)
                    filtered_data_final = [x for x in filtered_data if x >= threshold_value]
                                    
                    # j = min(filtered_data_final)
                    # adjusted_values = [float(x) - float(j) for x in filtered_data_final]
                    adjusted_values = filtered_data_final
                else:
                    # j = min(temp)
                    # adjusted_values = [float(x) - float(j) for x in temp]
                    adjusted_values = temp

                # Step 1: Estimate the rate parameter (lambda) for the exponential distribution
                lambda_hat = 1 / np.mean(adjusted_values)
              
                # Step 2: Compute theoretical quantiles for the exponential distribution
                percentiles = [25, 50, 75, 90, 95]
                theoretical_quantiles = np.percentile(np.random.exponential(scale=1/lambda_hat, size=len(adjusted_values)), percentiles)

                # Step 3: Compute sample quantiles for your data
                sample_quantiles = np.percentile(adjusted_values, percentiles)

                # Step 4: Combine both theoretical and sample quantiles
                qq_data = list(zip(percentiles, theoretical_quantiles, sample_quantiles))

                temp2 = np.random.exponential(scale=1/lambda_hat, size=len(adjusted_values))
                # res = stats.cramervonmises(temp, "expon")
                res = stats.cramervonmises_2samp(np.array(adjusted_values), temp2)

                # Add run index to each row (to distinguish runs in the CSV)
                for perc, theo, samp in qq_data:
                    all_qq_data.append([qps, run, percentile_to_remove_upper, perc, theo, samp, res.pvalue])
                

                # # Perform the Anderson-Darling test
                # ad_stat, critical_values, sig_level = anderson(adjusted_values, dist='expon')
                # print(ad_stat)
                # print(critical_values)
                # print(sig_level)
        
    # Step 5: Write the results to a CSV file
    output_file = os.path.join(path, "all_qq_data_response.csv")
    with open(output_file, mode='w') as file:
        writer = csv.writer(file)

        # Write header
        writer.writerow(["Lambda", "Run", "Percentile to Remove", "Percentile", "Theoretical Quantile", "Sample Quantile", "P value"])

        # Write all Q-Q data
        for row in all_qq_data:
            writer.writerow(row) 

def print_arrival(expstats, dir):
    
    path = os.path.join(dir, "results")
    arrival_file = os.path.join(path, "arrival.csv")
    temp=0
    for key in expstats[0].keys():
        temp = key
        break
    max_runs= (max([int(k) for k in expstats[0][temp]['arr'].keys()])) + 1

    label1=[]
    label2=[]
    for key in expstats[0].keys():
        for i in range(max_runs):
            label1.append(key)
            label2.append(i)
    
    max_lines=len([line for key in expstats[0].keys() for lines in expstats[0][key]['arr'] for line in expstats[0][key]['arr'][lines]])
    
    # Write the dictionary to the CSV file
    with open(arrival_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        
        # Write the header row (QPS values as columns)
        writer.writerow(label1)
        writer.writerow(label2)
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_lines):
            row=[]
            for qps in expstats[0]:
                for run in expstats[0][qps]['arr']:

                    if i < len(expstats[0][qps]['arr'][run]):
                        row.append(expstats[0][qps]['arr'][run][i])
                    else:
                        row.append("")
            writer.writerow(row)

def print_utilization(expstats, dir):

    path = os.path.join(dir, "results")
    util_file = os.path.join(path, "util.csv")
    temp=0
    for key in expstats[0].keys():
        temp = key
        break

    max_runs= (max([int(k) for k in expstats[0][temp]['arr'].keys()])) + 1
  
    # Write the dictionary to the CSV file
    with open(util_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        
        row1 = []
        row2 = []
        # Write the header row (QPS values as columns)
        for key in expstats[0].keys():
            row1.append(key)
            for i in range(cores):
                row1.append("")
                row2.append(i)
        writer.writerow(row1)
        writer.writerow(row2)
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_runs):
            # row = [statistics.mean(expstats[0][qps]['util'][i]) for tmp in expstats[0][qps]["util"][i] for qps in expstats[0].keys()]
            row = [statistics.mean(expstats[0][qps]["util"][i][core]) for qps in expstats[0].keys() for core in expstats[0][qps]["util"][i]]
            writer.writerow(row)

def print_turbostat_residency(expstats, dir):
    
    path = os.path.join(dir, "results")
    turbostat_file = os.path.join(path, "turbostat-hw-cstate.csv")

    # remove first and last measurements
    for queries in expstats[0]:
        for runs in expstats[0][queries]["cstates-turbostat"]:
            for core, values in expstats[0][queries]["cstates-turbostat"][runs].items():
                for metric, value in expstats[0][queries]["cstates-turbostat"][runs][core].items():                   
                    expstats[0][queries]["cstates-turbostat"][runs][core][metric].pop(0)
                    expstats[0][queries]["cstates-turbostat"][runs][core][metric].pop(0)
                    expstats[0][queries]["cstates-turbostat"][runs][core][metric].pop(-1)
    
    result = {}
    # calculate average for each metric each run and core 0
    for queries in expstats[0]:
        result[queries] = {}
        for runs in expstats[0][queries]["cstates-turbostat"]:
            # print(expstats[0][queries]["cstates-turbostat"][runs])
            for metric, value in expstats[0][queries]["cstates-turbostat"][runs][0].items():
                if metric not in result[queries]:
                    result[queries][metric] = []
                result[queries][metric].append(statistics.mean(expstats[0][queries]["cstates-turbostat"][runs][0][metric]))
    
    with open(turbostat_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        row = []
        row.append("")
        row.append("C0")
        row.append("C1")
        row.append("C6")
        writer.writerow(row)
        for queries in result:
            row=[]
            c6 = statistics.mean(result[queries]['CPU%c6'])
            c1 = statistics.mean(result[queries]['CPU%c1'])
            c0 = 100 - c1 - c6
            row.append(queries)
            row.append(c0)
            row.append(c1)
            row.append(c6)
            writer.writerow(row)

    turbostat_sw_file = os.path.join(path, "turbostat-sw-cstate.csv")
    with open(turbostat_sw_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        row = []
        row.append("")
        row.append("C0")
        row.append("C1")
        row.append("C1E")
        row.append("C6")
        writer.writerow(row)
        for queries in result:
            row=[]
            c6 = statistics.mean(result[queries]['C6%'])
            c1e = statistics.mean(result[queries]['C1E%']) 
            c1 = statistics.mean(result[queries]['C1%'])
            c0 = 100 - c1 - c1e - c6
            row.append(queries)
            row.append(c0)
            row.append(c1)
            row.append(c1e)
            row.append(c6)
            writer.writerow(row)
            
def print_avg(expstats, dir):
    path = os.path.join(dir, "results")
    avg_file = os.path.join(path, "avg.csv")
    percentile_file = os.path.join(path, "99th.csv")
    qps_file = os.path.join(path, "qps.csv")
    key=0
    temp=0
    for key in expstats[0].keys():
        temp = key
        break
    
    max_runs= (max([int(k) for k in expstats[0][str(temp)]['arr'].keys()])) + 1
  
    # Write the dictionary to the CSV file
    with open(avg_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        
        # Write the header row (QPS values as columns)
        writer.writerow(expstats[0].keys())
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_runs):
            row = [expstats[0][qps]['avg'][i] if i < len(expstats[0][qps]['avg']) else '' for qps in expstats[0].keys()]
            writer.writerow(row)
    
    # Write the dictionary to the CSV file
    with open(percentile_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        
        # Write the header row (QPS values as columns)
        writer.writerow(expstats[0].keys())
        
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_runs):
            row = [expstats[0][qps]['99th'][i] if i < len(expstats[0][qps]['99th']) else '' for qps in expstats[0].keys()]
            writer.writerow(row)
    
    # Write the dictionary to the CSV file
    with open(qps_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        
        # Write the header row (QPS values as columns)
        writer.writerow(expstats[0].keys())
        
        # Write the data rows (align values by adding empty strings for shorter lists)
        for i in range(max_runs):
            row = [expstats[0][qps]['qps'][i] if i < len(expstats[0][qps]['qps']) else '' for qps in expstats[0].keys()]
            writer.writerow(row)
    
def print_to_file(expstats, dir):
    print("irtaaaaaaaaaaaaa")
    newpath=os.path.join(dir, "results")
    if not os.path.exists(newpath):
        os.makedirs(newpath)
    
    print_turbostat_residency(expstats, dir)
    print_avg(expstats, dir)
    print_utilization(expstats, dir)
    print_arrival(expstats, dir)
    print_response(expstats, dir)
    print_server_timer(expstats, dir)
    print_idle_time_systemtap(expstats, dir)
    print("efiaaaaaa")
def get_idle_time_systemtap(dir,expstats):
    print("irtaaaaaaa")
    idle_file=os.path.join(dir, "systemtap_idle.log")

    if "stap-idle" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["stap-idle"] = {}

    if not os.path.isfile(idle_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1] = {}
        return
    
    expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1] = {}

    # Open the file and read lines
    with open(idle_file, 'r') as file:
        lines = file.readlines()
    
    start_ts = 0
    flag=0
    tempcpu={}
    for i in range(40):
        tempcpu[i]=0
        expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1][str(i)] = []
    expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1][all] = []

    for line in lines:
        if "TEST_OFF" in line:
            end_ts = int(line.split()[0])

    for line in lines:
        if "TEST_START" in line:
            start_ts = int(line.split()[0])
            flag=1
        elif not flag:
            continue

        if flag:
            
            if not "All" in line and not "all-idle" in line:
                ts = int(line.split()[0])
                cpu = line.split()[1]
                state = line.split()[2]
            
            if "System leaves all-idle state at" in line:
                if int(line.split()[-1].replace('us)',''))*1000 > int(start_ts) and ((int (line.split()[5].replace('us','')))*1000) < end_ts:
                    expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1][all].append(((int (line.split()[5].replace('us','')))*1000 - int(line.split()[-1].replace('us)','')))/1000) 
                
            if ts < start_ts or ts > end_ts:
                continue
            elif "IDLE_ON" in state:
                tempcpu[int(cpu)] = int(ts)
            elif "IDLE_OFF" in state and tempcpu[int(cpu)]!=0:
                expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1][str(cpu)].append((int(ts) - int(tempcpu[int(cpu)]))/1000)
                tempcpu[int(cpu)] = 0
            
    expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1]['start_ts'] = start_ts
    expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1]['end_ts'] = end_ts 

def get_active_time_systemtap(dir,expstats):
    print("irtaaaaaaa")
    idle_file=os.path.join(dir, "systemtap_idle.log")

    if "stap-active" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["stap-active"] = {}

    if not os.path.isfile(idle_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        expstats[get_query(dir)]["stap-active"][int(get_run(dir))-1] = {}
        return
    
    expstats[get_query(dir)]["stap-active"][int(get_run(dir))-1] = {}

    # Open the file and read lines
    with open(idle_file, 'r') as file:
        lines = file.readlines()
    
    start_ts = 0
    flag=0
    tempcpu={}
    for i in range(40):
        tempcpu[i]=0
        expstats[get_query(dir)]["stap-active"][int(get_run(dir))-1][str(i)] = []
    expstats[get_query(dir)]["stap-active"][int(get_run(dir))-1][all] = []

    for line in lines:
        if "TEST_OFF" in line:
            end_ts = int(line.split()[0])

    for line in lines:
        if "TEST_START" in line:
            start_ts = int(line.split()[0])
            flag=1
        elif not flag:
            continue

        if flag:
            
            if not "All" in line and not "all-idle" in line:
                ts = int(line.split()[0])
                cpu = line.split()[1]
                state = line.split()[2]
            
            if ts < start_ts or ts > end_ts:
                continue
            elif "TEST_ON" in state:
                tempcpu[int(cpu)] = int(ts)
            elif "TEST_OFF" in state and tempcpu[int(cpu)]!=0:
                expstats[get_query(dir)]["stap-active"][int(get_run(dir))-1][str(cpu)].append((int(ts) - int(tempcpu[int(cpu)]))/1000)
                tempcpu[int(cpu)] = 0
            
    expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1]['start_ts'] = start_ts
    expstats[get_query(dir)]["stap-idle"][int(get_run(dir))-1]['end_ts'] = end_ts 
    
def get_server_timer_samples(dir,expstats):

    timer_file=os.path.join(dir, "thread_0_times.log")
    if "server-timer-actual" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["server-timer-actual"] = {}
    
    if not os.path.isfile(timer_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        expstats[get_query(dir)]["server-timer-actual"][int(get_run(dir))-1] = []
        return

    # Open the file and read lines
    with open(timer_file, 'r') as file:
        lines = file.readlines()

    # Extract the first column from each line
    expstats[get_query(dir)]["server-timer-actual"][int(get_run(dir))-1] = [float(line.split()[0]) for line in lines if len(line.split()) > 0]
   
    #######################Expected###################################
    timer_file=os.path.join(dir, "thread_0_delay.log")
    if "server-timer-exp" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["server-timer-exp"] = {}
    
    if not os.path.isfile(timer_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        expstats[get_query(dir)]["server-timer-exp"][int(get_run(dir))-1] = []
        return

    # Open the file and read lines
    with open(timer_file, 'r') as file:
        lines = file.readlines()

    # Extract the first column from each line
    expstats[get_query(dir)]["server-timer-exp"][int(get_run(dir))-1] = [line.split()[0] for line in lines if len(line.split()) > 0]
   

def get_response_samples(dir, expstats):

    response_file=os.path.join(dir, "response_times_thread_1.txt")
    if "resp" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["resp"] = {}
    
    if not os.path.isfile(response_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        expstats[get_query(dir)]["resp"][int(get_run(dir))-1] = []
        return

    # Open the file and read lines
    with open(response_file, 'r') as file:
        lines = file.readlines()

    # Extract the third column from each line
    expstats[get_query(dir)]["resp"][int(get_run(dir))-1] = [float(line.split()[2]) for line in lines[1:] if len(line.split()) > 2]
   
def get_arrival_samples(dir, expstats):
    
    arrival_file=os.path.join(dir, "timestamps_thread_1.log")
    if "arr" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["arr"] = {}
           
    if not os.path.isfile(arrival_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        expstats[get_query(dir)]["arr"][int(get_run(dir))-1] = []
        return
    
    # Open the file and read timestamps
    with open(arrival_file, 'r') as file:
        timestamps = [float(line.strip()) for line in file]
  
    # Calculate intervals (differences between consecutive timestamps)
    expstats[get_query(dir)]["arr"][int(get_run(dir))-1] = [timestamps[i+1] - timestamps[i] for i in range(len(timestamps) - 1)]
    

def get_utilization(dir,expstats):

    tmp=[]
    util_file=os.path.join(dir, "mpstat.log")
    if "util" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["util"] = {}
    
    expstats[get_query(dir)]["util"][int(get_run(dir))-1] = {}

    for i in range(cores):
        expstats[get_query(dir)]["util"][int(get_run(dir))-1][str(i)]=[]
    
    # check if client file exists and contains the key Latency
    if not os.path.isfile(util_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        for i in range(cores):
            expstats[get_query(dir)]["util"][int(get_run(dir))-1][str(i)].append(float(0))
        return
    
    # If file exists in the right format get the idle time of core zero only skip 2 first and last measurement
    with open(util_file) as f:    
        for line in f:            
            if len(line.split()) > 1 and not "Average" in line and not "CPU" in line and not "all" in line:
                expstats[get_query(dir)]["util"][int(get_run(dir))-1][str(line.split()[2])].append(float(100 - float(line.split()[-1])))

    for i in range(cores):
        expstats[get_query(dir)]["util"][int(get_run(dir))-1][str(i)].pop(0)
        expstats[get_query(dir)]["util"][int(get_run(dir))-1][str(i)].pop(0)
        expstats[get_query(dir)]["util"][int(get_run(dir))-1][str(i)].pop(-1)
    
    
    # expstats[get_query(dir)]["util"].append(statistics.mean(tmp))  

def get_turbostat_residency(dir, expstats):

    turbostat_file=os.path.join(dir, "turbostat.log")
    if "cstates-turbostat" not in  expstats[get_query(dir)]:
        expstats[get_query(dir)]["cstates-turbostat"] = {}
           
    if not os.path.isfile(turbostat_file) or expstats[get_query(dir)]["avg"][-1] == 0:
        expstats[get_query(dir)]["cstates-turbostat"][int(get_run(dir))-1] = {}
        return
   
    expstats[get_query(dir)]["cstates-turbostat"][int(get_run(dir))-1] = {}
    
    # Open the turbostat output file for reading
    with open(turbostat_file, 'r') as file:

        # Read all lines from the file
        lines = file.readlines()

    # Extract header and data rows
    header = lines[0].split()
    data_rows = [line.split() for line in lines[1:]]
    
    # Iterate over data rows
    for row in data_rows:

        if "Package" in row:
            continue

        # Extract core and data values
        if row[2] == "-":
            core = -1
        else:
            core = int(row[2])

        data_values = {header[i]: float(row[i]) for i in range(3, len(row))}

        # Check if the core already exists in the dictionary
        #print(str(j) + " " + str(core))
    
        if core in expstats[get_query(dir)]["cstates-turbostat"][int(get_run(dir))-1]:
            # Append new values to the existing dictionary
            existing_values = expstats[get_query(dir)]["cstates-turbostat"][int(get_run(dir))-1][core]
            for key, value in data_values.items():
                existing_values[key].append(value)
        else:
            # Create a new entry with the current values
            expstats[get_query(dir)]["cstates-turbostat"][int(get_run(dir))-1][core] = {key: [value] for key, value in data_values.items()}

    
def get_avg_response_time(dir,expstats):

    client_file=os.path.join(dir, "client.log")
    query=get_query(dir)

    # Initialize dictionary
    if "avg" not in expstats[get_query(dir)]:
        expstats[query]["avg"] = []
        expstats[query]["qps"] = []
        expstats[query]["99th"] = []

    # check if client file exists and contains the key Latency
    if not os.path.isfile(client_file):
        expstats[query]["avg"].append(0)
        expstats[query]["qps"].append(0)
        expstats[query]["99th"].append(0)
        return

    with open(client_file) as f:
        if "Latency" not in f.read():
            expstats[query]["avg"].append(0)
            expstats[query]["qps"].append(0)
            expstats[query]["99th"].append(0)
            return
    
    # If file exists in the right format
    with open(client_file) as f:
        for line in f:
            if "Latency" in line:
                                               
                avg=line.split()[1]
                percentile=line.split()[3]
                qps = next(f).split()[1]

                # Extract all matches as a list
                floatsavg = re.findall(r"-?\d+\.\d+", avg)
                floatspercentile = re.findall(r"-?\d+\.\d+", percentile)
                floatqps = re.findall(r"-?\d+\.\d+", qps)

                if "s" in re.split("[^a-zA-Z]*", avg): 
                    floatsavg[0]= float(floatsavg[0])*1000

                if "us" in re.split("[^a-zA-Z]*", avg): floatsavg[0]=float(floatsavg[0])/1000 
               
                if "s" in re.split("[^a-zA-Z]*", percentile): floatspercentile[0]=float(floatspercentile[0])*1000
                if "us" in re.split("[^a-zA-Z]*", percentile): floatspercentile[0]=float(floatspercentile[0])/1000 
                
                
                if "k" in re.split("[^a-zA-Z]*", qps): 
                    floatqps[0]=float(floatqps[0])*1000
                           
                expstats[query]["avg"].append(float(floatsavg[0]))
                expstats[query]["qps"].append(float(floatqps[0]))
                expstats[query]["99th"].append(float(floatspercentile[0]))
                return
        

def get_raw_data(dir, expstats):
    
    get_avg_response_time(dir, expstats)
    get_turbostat_residency(dir, expstats)
    get_utilization(dir,expstats)
    get_arrival_samples(dir, expstats)
    get_response_samples(dir, expstats)
    get_server_timer_samples(dir,expstats)
    get_idle_time_systemtap(dir,expstats)


def get_run(dir):
    return dir.split("-")[-3]

def get_query(dir):
    return dir.split("-")[-1]

# Function to extract the first number from a filename
def extract_first_number(filename):
    match = re.search(r'\d+', filename)  # Find the first sequence of digits
    return int(match.group()) if match else float('inf')  # Return the number or a large value if no number is found

def parse_single_exp(dir):
    
    expstats = {}
    file_list = os.listdir(dir)
    # Sort files numerically based on the first number
    numerical_sorted_list = sorted(file_list, key=extract_first_number)

    for f in numerical_sorted_list:
        exp_dir = os.path.join(dir, f)
        if not os.path.isdir(exp_dir) or f == "results":
            continue

        query=get_query(f)
        if query not in expstats:
            expstats[query]={}
                
        get_raw_data(exp_dir, expstats)
    
    return expstats


def parse_multiple_exp(dir):
    
    expsstats={}
    
    for f in os.listdir(dir):
        exp_dir = os.path.join(dir, f)
        if not os.path.isdir(exp_dir):
            continue
        if f == "results":
            continue

        #get configuration for experiment and parse raw data 
        expsstats.setdefault(f, []).append(parse_single_exp(exp_dir))
        # if "timer" in f and "extra" in f:
        #     print(expsstats[f])
        print_to_file(expsstats[f],exp_dir)

    # print(expsstats)


def main(argv):
    dir = argv[1]
    statss = parse_multiple_exp(dir)
        
if __name__ == '__main__':
    main(sys.argv) # type: ignore
