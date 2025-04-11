from os import listdir, path
from re import compile
from subprocess import check_output

# Function for gathering subjects for ciftify
def Ciftify_Subject_List(dataset: str, subjects: list, pattern: str):
    pattern = compile(pattern)
    subjects_dirs = []
    
    for subject in subjects:
        for entry in listdir(dataset):
            full_path = path.join(dataset, entry)
            if path.isdir(full_path) and pattern.match(entry):
                subjects_dirs.append(entry)
    
    return subjects_dirs


# Function to check number of slurm jobs remaining
def Slurm_Queue_open(output_path: str, slurm_user: str):
    jobs=check_output(["squeue", f"-u{slurm_user}", "-o '%.10i %.9p %40j %.8u %.10T %.10M %.6D %R'", "-a"]).decode("utf-8")
    with open(rf"{output_path}/queue.txt", 'w') as f:
        f.write(jobs)
    with open(rf"{output_path}/queue.txt", 'r') as f:
        jobs = (sum(1 for line in f)) - 1
    open_jobs = 500 - jobs
    
    return open_jobs
    
# Function for running ciftify on those subjects
def Run_Ciftify(dirs: list):
    pass
# Function for running MSM BL-each

# Function for MSM Short Time Windows

print(Ciftify_Subject_List(r"/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION", ["4223", "6944", "0861", "5224", "4911", "0912"], r".*_S_[0-9]+_.*"))