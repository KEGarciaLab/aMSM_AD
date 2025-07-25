import pandas as pd

# import data on all subjects
print("Importing Data")
subject_data = pd.read_excel('D:\Desktop\Work\Data\Presentation\ADNI_Subjects.xlsx')

# clean subject numbers
print("Cleaning Subject IDs")
for i, sub_id in enumerate(subject_data['SubjID']):
    split_id = sub_id.split("_")
    subject_data.at[i,'SubjID'] = split_id[2]
    
# clean visit numbers
print("Cleaning Visits")
for i, visit in enumerate(subject_data['Visit']):
    if visit == 'BL':
        subject_data.at[i, 'Visit'] = 0
    else:
        subject_data.at[i, 'Visit'] = visit[1:]
subject_data['Visit'] = subject_data['Visit'].apply(pd.to_numeric)

# get subset of data needed
print("Subsetting Data")
sub_id = subject_data[['SubjID', 'Visit']]
ten_year_sub_id = sub_id[sub_id['Visit'] >= 120]
grouped_sub_id = ten_year_sub_id.groupby('SubjID')
test_sub_ids = list(grouped_sub_id.groups.keys())

# import and clean data of processed subjects
with open("D:\Desktop\Work\Data\Presentation\subjects.txt") as f:
    ran_subjects = f.read().splitlines()

for i, subject in enumerate(ran_subjects):
    split_subject = subject.split("_")
    subject_number = split_subject[1]
    if subject_number in ran_subjects:
        ran_subjects[i] = 'DELETE'
    
    else:
        ran_subjects[i] = split_subject[1]

ran_subjects[:] = (value for value in ran_subjects if value != 'DELETE')

# compare lists, keeping all that haven't been ran
need_to_run = list(set(test_sub_ids).difference(ran_subjects))
need_to_run.sort()

print(ran_subjects)
print(test_sub_ids)
print(need_to_run)

with open("D:\Desktop\Work\Data\Presentation\subjects_to_run.txt", "w+") as f:
    f.write('\n'.join(need_to_run))