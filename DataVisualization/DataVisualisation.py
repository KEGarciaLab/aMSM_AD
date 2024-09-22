import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

def clean_data(curvature_data_path, subject_data_path, merged_data_path):
    # Load data into pandas
    print('Loading data into pandas')
    curvature_data = pd.read_csv(curvature_data_path, converters={'SUBJECT_ID': str}).sort_values(by=['SUBJECT_ID','MONTH_NUMBER'])
    subject_data=pd.read_excel(subject_data_path)

    # Make subject data have the same format as datasheets
    print('Changing SubjID column')
    for row, subject in enumerate(subject_data['SubjID']):
        new_sub_id = subject[-4:]
        subject_data.loc[row, ['SubjID']] = new_sub_id
    subject_data = subject_data.sort_values(by=['SubjID', 'Visit'])
        
    # Rename Columns for Join
    print("Renaming columns to match")
    subject_data = subject_data.rename(columns={'SubjID' : 'SUBJECT_ID', 'Visit' : 'TIME_POINT'})
    
    # Join Tables
    print("Joining tables")
    joined_data = pd.merge(
        curvature_data, subject_data, how="left", on=['SUBJECT_ID', 'TIME_POINT']
    )
    
    # Write to new sheet
    print(f"Writing to new csv located at {merged_data_path}")
    joined_data.to_csv(merged_data_path)
    
    input("Data cleaning done press enter to continue")
    
def generate_group_graph(data_sheet, group, metric, group_id):
    plt.figure(figsize=(20, 14))
    for key in group:
        grouped_data = data_sheet.get_group(key)
        plt.xlabel('Month of Scan')
        plt.ylabel(metric)
        plt.plot(grouped_data['MONTH_NUMBER'], grouped_data[metric], label=f'Subject {key}')
    plt.xticks(np.arange(0, 210, step=6))
    plt.title(f'{group_id} {metric}')
    plt.legend(loc='lower right')
    plt.savefig(f'D:\Desktop\Work\Data\Presentation\Graphs\Test\{group_id}_{metric}.png')
    plt.close()


def generate_single_graph(data_sheet, subject, metric):
    data = data_sheet.get_group(subject)
    months = data['MONTH_NUMBER'].to_numpy()
    metric_array = data[metric].to_numpy()
    a,b = np.polyfit(months, metric_array, 1)
    plt.figure(figsize=(20, 14))
    plt.scatter(months, metric_array)
    plt.plot(months, metric_array)
    plt.plot(months, a*months+b, linestyle='--')
    plt.xticks(np.arange(0, 210, step=6))
    plt.title(f'{subject} {metric}')
    plt.savefig(f'D:\Desktop\Work\Data\Presentation\Graphs\Test\{subject}_{metric}.png')
    plt.close()

path_curv = 'D:\Desktop\Work\Data\Presentation\ADNI_Datasheet-CP-no_dups.csv'
path_subj = 'D:\Desktop\Work\Data\Presentation\ADNI_Subjects.xlsx'

clean_data(path_curv, path_subj, 'D:\\Desktop\\Work\\Scripts\\MyScripts\\repos\\aMSM_AD\\Utility\\JoinedData.csv')