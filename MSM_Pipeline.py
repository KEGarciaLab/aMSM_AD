import sys
from os import listdir, path, makedirs
from re import compile
from subprocess import check_output, run
from time import sleep
from string import Template
from typing import Literal

# class for logging
class Tee:
    def __init__(self, *streams):
        self.streams = streams
    
    def write(self, message):
        for stream in self.streams:
            stream.write(message)
            stream.flush()
    
    def flush(self):
        for stream in self.streams:
            stream.flush()
            
log_path = path.expanduser('~/Scripts/MSM_Pipeline/output/full_pipeline_log.txt')
log_file = open(log_path, 'w')

sys.stdout = Tee(sys.__stdout__, log_file)
sys.stderr = Tee(sys.__stderr__, log_file)


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
def Slurm_Queue_Open(slurm_user: str):
    jobs = check_output(["squeue", f"-u{slurm_user}", "-o '%.10i %.9p %40j %.8u %.10T %.10M %.6D %R'", "-a"]).decode("utf-8")
    user_home = path.expanduser('~')
    output_dir = rf"{user_home}/Scripts/MSM_Pipeline/output"
    
    makedirs(output_dir, exist_ok=True)
    with open(rf"{user_home}/Scripts/MSM_Pipeline/output/queue.txt", 'w+') as f:
        f.write(jobs)
    with open(rf"{user_home}/Scripts/MSM_Pipeline/output/queue.txt", 'r') as f:
        jobs = (sum(1 for line in f)) - 1
    open_jobs = 500 - jobs
    
    return open_jobs
    

# Function for running ciftify on list of subjects
def Run_Ciftify(dataset: str, directories: list, delimiter: str, subjuect_index: int, time_index: int, output_path: str, slurm_account: str, slurm_user: str, slurm_email: str):
    user_home = path.expanduser('~')
    temp_output = path.join(user_home, "Scripts", "MSM_Pipeline", "output", "ciftify_scripts")
    
    makedirs(temp_output, exist_ok=True)
    for directory in directories:
        jobs_open = Slurm_Queue_Open(slurm_user=slurm_user)
        while jobs_open <= 0:
            sleep(2 * 3600)
            jobs_open = Slurm_Queue_Open(slurm_user=slurm_user)

        fields = directory.split(delimiter)
        subject = fields[subjuect_index]
        time_point = fields[time_index]
        subject_output_path = path.join(output_path, f"Subject_{subject}_{time_point}")
        makedirs(output_path, exist_ok=True)
        
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "Ciftify_template.txt")
        with open(template_path, 'r') as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(subject=subject, time_point=time_point, account=slurm_account, email=slurm_email, dataset=dataset, output_dir=subject_output_path, dir=directory)
        
        with open(fr"{temp_output}/Subject_{subject}_{time_point}_recon_all.sh", 'w') as f:
            f.write(to_write)
            
        run(fr"sbatch {temp_output}/Subject_{subject}_{time_point}_recon_all.sh", shell=True)
  
                
# Function to get all time points for a subject
def Get_Subject_Time_Points(dataset: str, subject_id: str):
    subject_dirs = []
    time_points = []
    pattern = compile(fr"Subject_{subject_id}_.*")
    for entry in listdir(dataset):
        full_path = path.join(dataset, entry)
        if path.isdir(full_path) and pattern.match(entry):
                subject_dirs.append(entry)
    
    for directory in subject_dirs:
        fields = directory.split("_")
        time_point = fields[2]
        if time_point not in time_points:
            time_points.append(time_point)
    
    time_points.sort()
    return time_points

def Get_MSM_Files(dataset: str, subject: str, time_point: str):
    # get directory containing data and name prefix
    subject_dir = path.join(dataset, f"Subject_{subject}_{time_point}")
    subdirs = [ directory for directory in listdir(subject_dir) if path.isdir(path.join(subject_dir, directory)) and directory != "zz_templates"]
    if not subdirs:
        return
    subject_dir = path.join(subject_dir, subdirs[0])
    subject_full_name = subdirs[0]
    
    # get the name of the location of anatomical and spherical surfaces
    subject_thickness_dir = path.join(subject_dir, "T1w", "fsaverage_LR32k")
    subject_curvature_dir = path.join(subject_dir, "MNINonLinear", "fsaverage_LR32k")
    left_anatomical_surface = path.join(subject_thickness_dir, f"{subject_full_name}.L.midthickness.32k_fs_LR.surf.gii")
    right_anatomical_surface = path.join(subject_thickness_dir, f"{subject_full_name}.R.midthickness.32k_fs_LR.surf.gii")
    left_spherical_surface = path.join(subject_thickness_dir, f"{subject_full_name}.L.sphere.32k_fs_LR.surf.gii")
    right_spherical_surface = path.join(subject_thickness_dir, f"{subject_full_name}.L.sphere.32k_fs_LR.surf.gii")
    
    # run seperate commands for curvatures
    run(fr"wb_command -cifti-separate {subject_curvature_dir}/{subject_full_name}.thickness.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT {subject_curvature_dir}/{subject_full_name}_Thickness.L.func.gii -metric CORTEX_RIGHT {subject_curvature_dir}/{subject_full_name}_Thickness.R.func.gii", shell=True)
    run(fr"wb_command -cifti-separate {subject_curvature_dir}/{subject_full_name}.curvature.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT {subject_curvature_dir}/{subject_full_name}_Curvature.L.func.gii -metric CORTEX_RIGHT {subject_curvature_dir}/{subject_full_name}_Curvature.R.func.gii", shell=True)
    
    # get full path for curvature files
    left_curvature = fr"{subject_curvature_dir}/{subject_full_name}_Curvature.L.func.gii"
    right_curvature = fr"{subject_curvature_dir}/{subject_full_name}_Curvature.R.func.gii"
    
    # return all files as list
    subject_files = [left_anatomical_surface, right_anatomical_surface, left_spherical_surface, right_spherical_surface, left_curvature, right_curvature]
    return subject_files


MSM_Mode = Literal["forward", "reverse"]

# Function for running MSM commands
def Run_MSM(dataset: str, output: str, subject: str, younger_timepoint: str, older_timepoint: str, mode: MSM_Mode, levels: int, config: str,
            max_anat: str, max_cp: str, slurm_email: str, slurm_account: str, slurm_user: str):
    
    user_home = path.expanduser('~')
    if mode == "forward":
        temp_output = path.join(user_home, "Scripts", "MSM_Pipeline", "output", "MSM_scripts", fr"{subject}_{younger_timepoint}_to_{older_timepoint}")
    elif mode == "reverse":
        temp_output = path.join(user_home, "Scripts", "MSM_Pipeline", "output", "MSM_scripts", fr"{subject}_{older_timepoint}_to_{younger_timepoint}")
    print(f"creating the following script directory: {temp_output}")
    makedirs(temp_output, exist_ok=True)
    
    print(f"Retriving files for time points {younger_timepoint} and {older_timepoint}")
    younger_files = Get_MSM_Files(dataset=dataset, subject=subject, time_point=younger_timepoint)
    older_files = Get_MSM_Files(dataset=dataset, subject=subject, time_point=older_timepoint)
    
    if not younger_files or not older_files:
        print("no files found skipping this run")
        return
    
    print("Younger time point:", *younger_files, sep=' ')
    print("Older time point:", *older_files, sep=" ")
    
    if mode == "forward":
        output = path.join(output, fr"{subject}_{younger_timepoint}_to_{older_timepoint}")
        left_file_prefix = fr"{subject}_L_{younger_timepoint}-{older_timepoint}."
        right_file_prefix = fr"{subject}_R_{younger_timepoint}-{older_timepoint}."
        
        print()
        print(fr"Generating script file {temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_forward_L.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(subject=subject, starting_time=younger_timepoint, ending_time=older_timepoint, user_home=user_home, email=slurm_email, account=slurm_account,
                                    levels=levels, config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4], oc=older_files[4], yas=younger_files[0],
                                    oas=older_files[0], f_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
        
        with open(fr"{temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write)
        
        jobs_open = Slurm_Queue_Open(slurm_user)
        print(f"Checking slurm queue for user {slurm_user}")
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = Slurm_Queue_Open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)
        
        (print)
        print(fr"Generating script {temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_forward_R.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(subject=subject, starting_time=younger_timepoint, ending_time=older_timepoint, user_home=user_home, email=slurm_email, account=slurm_account,
                                    levels=levels, config=config, yss=younger_files[3], oss=older_files[3], yc=younger_files[5], oc=older_files[5], yas=younger_files[1],
                                    oas=older_files[1], f_out=right_file_prefix, maxanat=max_anat, maxcp=max_cp)
        
        with open(fr"{temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write)
        
        jobs_open = Slurm_Queue_Open(slurm_user)
        print(f"Checking slurm queue for user {slurm_user}")
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = Slurm_Queue_Open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)
    
    elif mode == "reverse":
        output = path.join(output, fr"{subject}_{older_timepoint}_to_{younger_timepoint}")
        left_file_prefix = fr"{subject}_L_{older_timepoint}-{younger_timepoint}."
        right_file_prefix = fr"{subject}_R_{older_timepoint}-{younger_timepoint}."
        
        print()
        print(fr"Generating script {temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_reverse_L.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(subject=subject, starting_time=older_timepoint, ending_time=younger_timepoint, user_home=user_home, email=slurm_email, account=slurm_account,
                                    levels=levels, config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4], oc=older_files[4], yas=younger_files[0],
                                    oas=older_files[0], r_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
        
        with open(fr"{temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write)
        
        jobs_open = Slurm_Queue_Open(slurm_user)
        print(f"Checking slurm queue for user {slurm_user}")
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = Slurm_Queue_Open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)
        
        print()
        print(fr"Generating Script {temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_reverse_R.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(subject=subject, starting_time=older_timepoint, ending_time=younger_timepoint, user_home=user_home, email=slurm_email, account=slurm_account,
                                    levels=levels, config=config, yss=younger_files[3], oss=older_files[3], yc=younger_files[5], oc=older_files[5], yas=younger_files[1],
                                    oas=older_files[1], r_out=right_file_prefix, maxanat=max_anat, maxcp=max_cp)
        with open(fr"{temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write) 
        
        print(f"Checking slurm queue for user {slurm_user}")
        jobs_open = Slurm_Queue_Open(slurm_user)
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = Slurm_Queue_Open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)
    
        

# Function for MSM BL tp all
def Run_MSM_BL_To_All(dataset: str, output: str, starting_time: str, slurm_account: str, slurm_user: str, slurm_email: str, levels: int, config: str, max_anat: str, max_cp: str):
    
    subjects = []
    print("RETRIVING LIST OF SUBJECTS")
    print("*" * 50)
    for directory in listdir(dataset):
        full_path = path.join(dataset, directory)
        if path.isdir(full_path):
            fields = directory.split("_")
            subject = fields[1]
            if subject not in subjects:
                print(f"Found subject number {subject}")
                subjects.append(subject)
    
    subjects.sort()
    print("\nAll subjects found. Beginning MSM")
    print('*' *50)
    for subject in subjects:
        print(f"Serching for time points for subject {subject}")
        time_points = Get_Subject_Time_Points(dataset=dataset, subject_id=subject)
        if starting_time not in time_points:
            print(f"ERROR: Starting Time missing for {subject}! Proceeding to next subject")
        print(*time_points)
        print(f"The following time points have been located: ", *time_points, sep=' ')
        print()
        for time_point in time_points:
            if time_point != starting_time:
                Run_MSM(dataset, output, subject, starting_time, time_point, "forward", levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user)
                Run_MSM(dataset, output, subject, starting_time, time_point, "reverse", levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user)
                
                
Run_MSM_BL_To_All(
    fr"/N/project/aMSM_AD/ADNI/HCP/TO_BE_PROCESSED_FIRST",
    fr"/N/project/aMSM_AD/ADNI/HCP/MSM_T1W_ANATCONFIG",
    "BL",
    "r00540",
    "sarigdon",
    "sarigdon@iu.edu",
    6,
    fr"/N/project/aMSM_AS/ADNI/HCP/configAnatGrid6",
    fr"/N/project/aMSM_AS/ADNI/HCP/ico6sphere.LR.reg.surf.gii",
    fr"/N/project/aMSM_AS/ADNI/HCP/ico5sphere.LR.reg.surf.gii"
)