import matplotlib.pyplot as plt
import pandas as pd
import sys
import os
import re
import seaborn as sns
import matplotlib.patches as mpatches
import matplotlib.ticker as ticker
import numpy as np

from scipy.stats import gmean


dict_baseline = {}
dict_lazypoline = {}
dict_zpoline = {}
dict_vector = {}
dict_sud = {}



def Worker(filename):
    match = re.search(r'w(\d+)(?!\d)', filename)
    if match:
        return match.group(1)

def versioning(filename):
    for size in ["256kb", "64kb", "16kb", "4kb", "0kb"]:
        if size in filename:
            return size

def parse_requests_per_second(text):
    match = re.search(r'Requests/sec:\s*([\d.]+)', text)
    if match:
        requests_per_second = float(match.group(1))
        return requests_per_second
    else:
        return None

# Custom formatter to display y-axis ticks as powers of 10
def custom_formatter(x, pos):
    if x == 0:
        return "0"
    else:
        power = np.floor(np.log10(x))
        base = x / 10**power
        return r'${}\times10^{{{}}}$'.format(int(base) if base == int(base) else round(base, 1), int(power))



def calculate_mean_throughput(df):
    # Group by FileSize and Threads, then calculate the mean of Throughput
    stats_df = df.groupby(["File Size", "Threads", "version"])["Throughput (req/sec)"].agg(['mean', 'std']).reset_index()
    stats_df['RelativeStdDevThroughput'] = (stats_df['std'] / stats_df['mean']) * 100
    stats_df.rename(columns={"mean": "Throughput (req/sec)", "std": "StdDevThroughput"}, inplace=True)
    return stats_df


def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <folder_path>")
        sys.exit(1)

    folder_path = sys.argv[1]
    
    g,h,x,l,k,m = 0,0,0,0,0,0
    path2 = folder_path
    os.chdir(path2)
    for filename in sorted(os.listdir(path2)):
        # print(filename)
        if filename.endswith(".txt"):
            with open(filename, 'r') as fp:
                lines = fp.readlines()
                for line in lines:
                    if 'Requests/sec' in line:
                        # Use regular expression to find the floating point number that follows 'Requests/sec:'
                        match = re.findall(r"Requests/sec:\s*(\d+\.\d+)", line)
                        if match:
                            temp = float(match[0])

            if "zpoline" in filename:
                version = versioning(filename)
                Threads = Worker(filename)
                dict_zpoline[h] = {'Throughput (req/sec)': temp,
                                'File Size':version,
                                'Threads':Threads}
                h+=1
            elif "lazypoline" in filename:
                version = versioning(filename)
                Threads = Worker(filename)
                dict_lazypoline[g] = {"Throughput (req/sec)": temp,
                                "File Size":version,
                                "Threads":Threads}
                g+=1
            elif "vector" in filename:
                version = versioning(filename)
                Threads = Worker(filename)
                dict_vector[k] = {"Throughput (req/sec)": temp,
                                "File Size":version,
                                "Threads":Threads}
                k+=1
            elif "sud" in filename:
                version = versioning(filename)
                Threads = Worker(filename)
                dict_sud[l] = {"Throughput (req/sec)": temp,
                                "File Size":version,
                                "Threads":Threads}
                l+=1
            elif "baseline" in filename:
                version = versioning(filename)
                Threads = Worker(filename)
                dict_baseline[m] = {"Throughput (req/sec)": temp,
                                "File Size":version,
                                "Threads":Threads}
                m+=1
            else:
                    print("You must check the txt filename!! It doesn't contain LOAD or RUN words.")
        else:
            continue

    df_vector = pd.DataFrame(dict_vector).T
    df_sud = pd.DataFrame(dict_sud).T
    df_lazypoline = pd.DataFrame(dict_lazypoline).T
    df_sud = pd.DataFrame(dict_sud).T
    df_zploine = pd.DataFrame(dict_zpoline).T
    df_baseline = pd.DataFrame(dict_baseline).T

    df_vector['version'] = 'lazypoline with preserving xstate'
    df_sud['version'] = 'SUD'
    df_lazypoline['version'] = 'lazypoline without preserving xstate'
    df_zploine['version'] = 'zpoline'
    df_baseline['version'] = 'baseline'

    df_vector_stats = calculate_mean_throughput(df_vector)

    df_sud_stats = calculate_mean_throughput(df_sud)

    df_lazypoline_stats = calculate_mean_throughput(df_lazypoline)

    df_zploine_stats = calculate_mean_throughput(df_zploine)

    df_baseline_stats = calculate_mean_throughput(df_baseline)
    df_lazypoline_stats['lazyploine/baseline'] = df_lazypoline_stats["Throughput (req/sec)"]/df_baseline_stats["Throughput (req/sec)"]

    df_zploine_stats['zploine/baseline'] = df_zploine_stats["Throughput (req/sec)"]/df_baseline_stats["Throughput (req/sec)"]

    df_vector_stats['preversing/not preserving'] = df_vector_stats["Throughput (req/sec)"]/df_lazypoline_stats["Throughput (req/sec)"]

    min_index = df_lazypoline_stats[df_lazypoline_stats["Threads"] == "1"]['lazyploine/baseline'].idxmin()

    print("Worst CASE Thread 1 lazypoline without preservering xstate compared to baseline ",min(df_lazypoline_stats[df_lazypoline_stats["Threads"] == "1"]['lazyploine/baseline']))
    print("Worst CASE Thread 1 zpoline compared to baseline ",df_zploine_stats.loc[min_index, 'zploine/baseline'])
    # print(df_zploine_stats.loc[min_index, 'zploine/baseline']- min(df_lazypoline_stats[df_lazypoline_stats["Threads"] == "1"]['lazyploine/baseline']))
    print("Worst CASE Thread 1 preserving compared to lazypoline ", min(df_vector_stats[df_vector_stats["Threads"] == "1"]['preversing/not preserving']))
 
    # Combine all DataFrames
    df_combined_stats = pd.concat([df_vector_stats, df_sud_stats, df_lazypoline_stats, df_zploine_stats, df_baseline_stats])
    df_combined = pd.concat([df_vector, df_sud, df_lazypoline, df_zploine, df_baseline])
    df_combined_thread_1 = df_combined[df_combined["Threads"] == "1"]
    df_combined_thread_12 = df_combined[df_combined["Threads"] == "12"]

    df_combined_stats_1 = df_combined_stats[df_combined_stats["Threads"] == "1"]
    df_combined_stats_12 = df_combined_stats[df_combined_stats["Threads"] == "1"]
    print("MAX STD",  df_combined_stats["RelativeStdDevThroughput"].max())
    
    CB_color_cycle = ['#377eb8', '#ff7f00', '#4daf4a',
                  '#f781bf', '#a65628']
    fig, ax = plt.subplots(figsize=(8.5,4)) 
    sns.barplot(x='File Size', y='Throughput (req/sec)', hue='version', 
                data=df_combined_thread_1, order=["0kb", "4kb", "16kb", "64kb", "256kb"], 
                hue_order=["baseline", "zpoline",   "lazypoline without preserving xstate", "lazypoline with preserving xstate", "SUD"], palette=CB_color_cycle, errorbar='sd')
    xticks = ["0KB","4KB", "16KB", "64KB", "256KB"]

    num_locations = len(df_combined["version"].unique())


    ax.yaxis.set_major_formatter(plt.FuncFormatter(custom_formatter))
    ax.set_xticklabels(xticks) 

    l = ax.legend()
    l.set_title('')

    plt.tight_layout()
    plt.savefig('1_thread.png')
    fig.savefig('1_thread.eps', format='eps')
    plt.show()

    fig, ax = plt.subplots(figsize=(8.5,4)) 
    sns.barplot(x='File Size', y='Throughput (req/sec)', hue='version', 
                data=df_combined_thread_12, order=["0kb", "4kb", "16kb", "64kb", "256kb"], 
                hue_order=["baseline", "zpoline",   "lazypoline without preserving xstate", "lazypoline with preserving xstate", "SUD"], palette=CB_color_cycle, errorbar='sd')
    xticks = ["0KB","4KB", "16KB", "64KB", "256KB"]

    num_locations = len(df_combined["version"].unique())

    ax.yaxis.set_major_formatter(plt.FuncFormatter(custom_formatter))
    ax.set_xticklabels(xticks) 
    l = ax.legend()
    l.set_title('')
    plt.tight_layout()
    plt.savefig('12_threads.png')
    fig.savefig('12_threads.eps', format='eps')
    plt.show()
  

if __name__ == '__main__':
    main()
