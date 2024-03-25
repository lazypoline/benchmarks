import matplotlib.pyplot as plt
import pandas as pd
import sys
import os
from scipy.stats import gmean


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 script.py <folder_path>")
        sys.exit(1)

    folder_path = sys.argv[1]
    
    print("Folder path:", folder_path)

    if not os.path.isdir(folder_path):
        print("Error: The specified path is not a directory.")
        sys.exit(1)


    lazyploine = pd.read_csv( folder_path + "/lazyploine.txt", sep=',',  header=None)
    lazyploine_rw = pd.read_csv( folder_path + "/lazyploine_rewriting.txt", sep=',',  header=None)
    baseline = pd.read_csv( folder_path + "/micro_baseline.txt", sep=',',  header=None)
    zpoline = pd.read_csv( folder_path + "/zpoline.txt", sep=',',  header=None)
    sud_enable = pd.read_csv( folder_path + "/sud_baseline.txt", sep=',',  header=None)
    vector = pd.read_csv( folder_path + "/lazyploine_rewriting_vector.txt", sep=',',  header=None)
    lazyploine_sud_disable = pd.read_csv( folder_path + "/lazyploine_sud_disable.txt", sep=',',  header=None)


    dataframes = [lazyploine, lazyploine_rw, baseline, zpoline, sud_enable, vector, lazyploine_sud_disable]
    std = []

    for df in dataframes:
        df.columns = ['execution time']
        df["gmean"] = gmean(df['execution time'])
        std.append((df['execution time'].std()*100)/(df['execution time'].mean()))

    print("MAX std all over the benchmark results ", max(std))
    n_lazyploine = lazyploine["gmean"][0]/baseline["gmean"][0]
    n_lazyploine_rw = lazyploine_rw["gmean"][0]/baseline["gmean"][0]
    n_zpoline = zpoline["gmean"][0]/baseline["gmean"][0]
    n_sud_enable = sud_enable["gmean"][0]/baseline["gmean"][0]
    n_vector = vector["gmean"][0]/baseline["gmean"][0]
    n_lazyploine_sud_disable = lazyploine_sud_disable["gmean"][0]/baseline["gmean"][0]
    

    data = {'zpoline':n_zpoline,  'lazyploine':n_lazyploine_rw, 'lazyploine*':n_vector, 'SUD*':n_sud_enable,'SUD':n_lazyploine}
    zpoline_difference = n_zpoline
    
    print(data)

    sud_difference =n_sud_enable-1
    lazyploine_sud_disable_difference = n_lazyploine_sud_disable
    vector_difference = n_vector

    fig, ax = plt.subplots(figsize = (5, 1.2))
    
    plt.barh(["zpoline"], zpoline_difference, color='#ff7f00',  height=0.4,  align='center')
    plt.barh(["lazypoline"], lazyploine_sud_disable_difference, color='#4daf4a', height=0.4,  label="without SUD", align='center')
    plt.barh(["lazypoline"], sud_difference, left=lazyploine_sud_disable_difference, color='#999999', label = "enabling SUD", height=0.4, align='center')
    plt.barh(["lazypoline"], vector_difference - lazyploine_sud_disable_difference - sud_difference, left=sud_difference+lazyploine_sud_disable_difference , color=['#f781bf'], label = "preserving xstate", height=0.4, align='center')
    box = ax.get_position()
    ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])

    ax.legend(loc='center left', bbox_to_anchor=(1, 0.5))
    ax.invert_yaxis()
    plt.xlim(1, 2.5)
    plt.tight_layout()
    plt.xlabel('Overhead Factor Relative to Baseline',  fontsize=11) 
    fig.savefig(folder_path + '/micro_stacked.png',  bbox_inches='tight')
    fig.savefig(folder_path + '/micro_stacked.eps', format='eps',  bbox_inches='tight')
    plt.show()


if __name__ == '__main__':
    main()