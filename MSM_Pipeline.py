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


log_path = path.expanduser(
    '~/Scripts/MyScripts/Output/MSM_Pipeline/full_pipeline_log.txt')
makedirs(path.dirname(log_path), exist_ok=True)
log_file = open(log_path, 'w+')
sys.stdout = Tee(sys.__stdout__, log_file)
sys.stderr = Tee(sys.__stderr__, log_file)


# Function for gathering subjects for ciftify
def get_ciftify_subject_list(dataset: str, subjects: list, pattern: str):
    print("\nBegin ciftify subject list generation")
    print('*' * 50)
    print("Finding all files for the following subjects:")
    print(*subjects, sep='\n')
    subjects_dirs = []

    for subject in subjects:
        subject_pattern = pattern.replace('#', subject)
        subject_pattern = compile(subject_pattern)
        for entry in listdir(dataset):
            full_path = path.join(dataset, entry)
            if path.isdir(full_path) and subject_pattern.match(entry) and entry not in subjects_dirs:
                subjects_dirs.append(entry)

    return sorted(subjects_dirs)


# Function to check number of slurm jobs remaining
def is_slurm_queue_open(slurm_user: str):
    print(f"\nChecking slurm queue for {slurm_user}")
    jobs = check_output(
        ["squeue",
         f"-u{slurm_user}",
         "-o '%.10i %.9p %40j %.8u %.10T %.10M %.6D %R'", "-a"]).decode("utf-8")
    user_home = path.expanduser('~')
    output_dir = rf"{user_home}/Scripts/MyScripts/Output/MSM_Pipeline"

    makedirs(output_dir, exist_ok=True)
    with open(rf"{user_home}/Scripts/MyScripts/Output/MSM_Pipeline/queue.txt", 'w+') as f:
        f.write(jobs)
    with open(rf"{user_home}/Scripts/MyScripts/Output/MSM_Pipeline/queue.txt", 'r') as f:
        jobs = (sum(1 for line in f)) - 1
    open_jobs = 500 - jobs

    return open_jobs


# Function for running ciftify on list of subjects
def run_ciftify(dataset: str, directories: list, delimiter: str,
                subject_index: int, time_index: int, output_path: str, slurm_account: str,
                slurm_user: str, slurm_email: str):
    print("\nStarting ciftify runs")
    print('*' * 50)
    user_home = path.expanduser('~')
    temp_output = path.join(user_home, "Scripts", "MyScripts", "Output",
                            "MSM_Pipeline", "ciftify_scripts")

    makedirs(temp_output, exist_ok=True)
    for directory in directories:
        fields = directory.split(delimiter)
        subject = fields[subject_index]
        time_point = fields[time_index]
        subject_output_path = path.join(
            output_path, f"Subject_{subject}_{time_point}")
        makedirs(output_path, exist_ok=True)
        print(
            f"\nCiftify run for subject {subject} at time point {time_point}")

        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "Ciftify_template.txt")
        with open(template_path, 'r') as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(subject=subject, time_point=time_point,
                                       account=slurm_account, email=slurm_email, dataset=dataset,
                                       output_dir=subject_output_path, dir=directory)

        with open(fr"{temp_output}/Subject_{subject}_{time_point}_recon_all.sh", 'w') as f:
            f.write(to_write)
        print(
            fr"Script wrote to {temp_output}/Subject_{subject}_{time_point}_recon_all.sh")

        jobs_open = is_slurm_queue_open(slurm_user=slurm_user)
        while jobs_open <= 0:
            sleep(2 * 3600)
            jobs_open = is_slurm_queue_open(slurm_user=slurm_user)
        run(fr"sbatch {temp_output}/Subject_{subject}_{time_point}_recon_all.sh",
            shell=True)


# Helper function for sorting time points
def sort_time_points(time_points: list, number_start_character: int, starting_time=None):
    copy = time_points.copy()
    if starting_time is not None and starting_time in time_points:
        copy.pop(time_points.index(starting_time))

    copy.sort(key=lambda time_point: int(
        time_point[number_start_character:]))

    if starting_time is not None and starting_time in time_points:
        copy.insert(0, starting_time)

    return copy


# Function to get all time points for a subject
def get_subject_time_points(dataset: str, subject: str, alphanumeric_timepoints: bool, time_point_number_start_character: str, starting_time=None):
    print(f"\nSerching for time points for subject {subject}")
    subject_dirs = []
    time_points = []
    pattern = compile(fr"Subject_{subject}_.*")
    for entry in listdir(dataset):
        full_path = path.join(dataset, entry)
        if path.isdir(full_path) and pattern.match(entry):
            subject_dirs.append(entry)

    for directory in subject_dirs:
        fields = directory.split("_")
        time_point = fields[2]
        if time_point not in time_points:
            time_points.append(time_point)

    if alphanumeric_timepoints:
        time_points = sort_time_points(
            time_points, time_point_number_start_character, starting_time)
    else:
        time_points.sort()
    print("The following time points have been located: ", *time_points, sep=' ')
    return time_points


def get_msm_files(dataset: str, subject: str, time_point: str):
    # get directory containing data and name prefix
    subject_dir = path.join(dataset, f"Subject_{subject}_{time_point}")
    subdirs = [directory for directory in listdir(subject_dir) if path.isdir(
        path.join(subject_dir, directory)) and directory != "zz_templates"]
    if not subdirs:
        return
    subject_dir = path.join(subject_dir, subdirs[0])
    subject_full_name = subdirs[0]

    # get the name of the location of anatomical and spherical surfaces
    subject_thickness_dir = path.join(subject_dir, "T1w", "fsaverage_LR32k")
    subject_curvature_dir = path.join(
        subject_dir, "MNINonLinear", "fsaverage_LR32k")
    left_anatomical_surface = path.join(
        subject_thickness_dir, f"{subject_full_name}.L.midthickness.32k_fs_LR.surf.gii")
    right_anatomical_surface = path.join(
        subject_thickness_dir, f"{subject_full_name}.R.midthickness.32k_fs_LR.surf.gii")
    left_spherical_surface = path.join(
        subject_thickness_dir, f"{subject_full_name}.L.sphere.32k_fs_LR.surf.gii")
    right_spherical_surface = path.join(
        subject_thickness_dir, f"{subject_full_name}.L.sphere.32k_fs_LR.surf.gii")

    # run seperate commands for curvatures
    run(fr"wb_command -cifti-separate {subject_curvature_dir}/{subject_full_name}.thickness.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT {subject_curvature_dir}/{subject_full_name}_Thickness.L.func.gii -metric CORTEX_RIGHT {subject_curvature_dir}/{subject_full_name}_Thickness.R.func.gii", shell=True)
    run(fr"wb_command -cifti-separate {subject_curvature_dir}/{subject_full_name}.curvature.32k_fs_LR.dscalar.nii COLUMN -metric CORTEX_LEFT {subject_curvature_dir}/{subject_full_name}_Curvature.L.func.gii -metric CORTEX_RIGHT {subject_curvature_dir}/{subject_full_name}_Curvature.R.func.gii", shell=True)

    # get full path for curvature files
    left_curvature = fr"{subject_curvature_dir}/{subject_full_name}_Curvature.L.func.gii"
    right_curvature = fr"{subject_curvature_dir}/{subject_full_name}_Curvature.R.func.gii"

    # return all files as list
    subject_files = [left_anatomical_surface, right_anatomical_surface,
                     left_spherical_surface, right_spherical_surface, left_curvature, right_curvature]
    return subject_files


Mode = Literal["forward", "reverse"]
# generate forward post processing images


def generate_post_processing_image(subject_directory: str, subject: str, starting_time: str, ending_time: str, resolution: str, mode: Mode):
    # get all files for for post processing
    if mode == "forward":
        left_younger_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.LYAS.{resolution}.surf.gii")
        right_younger_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.RYAS.{resolution}.surf.gii")
        left_older_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
        right_older_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
        right_older_avg_surface = None
        left_older_avg_surface = None
    elif mode == "reverse":
        left_younger_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
        right_younger_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
        left_older_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.LOAS.{resolution}.surf.gii")
        right_older_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.ROAS.{resolution}.surf.gii")

    left_surface_map = path.join(
        subject_directory, f"{subject}_L_{starting_time}-{ending_time}.surfdist.{resolution}.func.gii")
    right_surface_map = path.join(
        subject_directory, f"{subject}_R_{starting_time}-{ending_time}.surfdist.{resolution}.func.gii")
    avg_left_surface_map = path.join(
        subject_directory, f"{subject}_L_{starting_time}-{ending_time}.surfdist.{resolution}.func.gii")
    avg_right_surface_map = path.join(
        subject_directory, f"{subject}_R_{starting_time}-{ending_time}.surfdist.{resolution}.func.gii")
    spec_file = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}.spec")

    # add to spec file
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_LEFT {left_younger_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_LEFT {left_older_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_LEFT {left_surface_map}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_RIGHT {right_younger_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_RIGHT {right_older_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_RIGHT {right_surface_map}", shell=True)

    # create scene file for auto scale
    script_dir = path.dirname(path.realpath(__file__))
    if mode == "forward":
        template_path_auto_scale = path.join(
            script_dir, "post_processing_template_forward.scene")
        template_path_set_scale = path.join(
            script_dir, "post_processing_set_scale_template_forward.scene")
    elif mode == "reverse":
        template_path_auto_scale = path.join(
            script_dir, "post_processing_template_reverse.scene")
        template_path_set_scale = path.join(
            script_dir, "post_processing_set_scale_template_forward.scene")

    with open(template_path_auto_scale, "r") as f:
        template_read_auto_scale = f.read()
    template_auto_scale = Template(template_read_auto_scale)
    to_write_auto_scale = template_auto_scale.substitute(
        left_younger_surface=left_younger_surface,
        left_older_surface=left_older_surface,
        left_surface_map=left_surface_map,
        right_younger_surface=right_younger_surface,
        right_older_surface=right_older_surface,
        right_surface_map=right_surface_map
    )
    template_auto_scale_output = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}.scene")
    with open(template_auto_scale_output, "w+") as f:
        f.write(to_write_auto_scale)

    # create scene file for set scale
    with open(template_path_set_scale, "r") as f:
        template_read_set_scale = f.read()
    template_set_scale = Template(template_read_set_scale)
    to_write_set_scale = template_set_scale.substitute(
        left_younger_surface=left_younger_surface,
        left_older_surface=left_older_surface,
        left_surface_map=left_surface_map,
        right_younger_surface=right_younger_surface,
        right_older_surface=right_older_surface,
        right_surface_map=right_surface_map
    )
    template_set_scale_output = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}_SET-SCALE.scene")
    with open(template_set_scale_output, "w+") as f:
        f.write(to_write_set_scale)

    # generate images
    scene_auto_scale = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}.scene")
    scene_set_scale = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}_SET-SCALE.scene")
    run(f"wb_command -show-scene {scene_auto_scale} {subject_directory}/{subject}_{starting_time}-{ending_time}.png 1024 512", shell=True)
    run(f"wb_command -show-scene {scene_set_scale} {subject_directory}/{subject}_{starting_time}-{ending_time}_SET-SCALE.png 1024 512", shell=True)


# Function for running MSM commands
def run_msm(dataset: str, output: str, subject: str, younger_timepoint: str,
            older_timepoint: str, mode: Mode, levels: int, config: str,
            max_anat: str, max_cp: str, slurm_email: str,
            slurm_account: str, slurm_user: str):

    user_home = path.expanduser('~')
    if mode == "forward":
        temp_output = path.join(user_home, "Scripts", "MyScripts", "Output", "MSM_Pipeline",
                                "MSM_scripts", fr"{subject}_{younger_timepoint}_to_{older_timepoint}")
    elif mode == "reverse":
        temp_output = path.join(user_home, "Scripts", "MyScripts", "Output", "MSM_Pipeline",
                                "MSM_scripts", fr"{subject}_{older_timepoint}_to_{younger_timepoint}")
    print(f"Creating the following script directory: {temp_output}")
    makedirs(temp_output, exist_ok=True)

    print(
        f"\nRetriving files for time points {younger_timepoint} and {older_timepoint}")
    younger_files = get_msm_files(
        dataset=dataset, subject=subject, time_point=younger_timepoint)
    older_files = get_msm_files(
        dataset=dataset, subject=subject, time_point=older_timepoint)

    if not younger_files or not older_files:
        print("no files found skipping this run")
        return

    print("Younger time point:", *younger_files, sep='\n')
    print("Older time point:", *older_files, sep="\n")

    if mode == "forward":
        output = path.join(
            output, fr"{subject}_{younger_timepoint}_to_{older_timepoint}")
        makedirs(output, exist_ok=True)
        left_file_prefix = fr"{output}/{subject}_L_{younger_timepoint}-{older_timepoint}."
        right_file_prefix = fr"{output}/{subject}_R_{younger_timepoint}-{older_timepoint}."

        print(" \n")
        print(
            fr"Generating script file {temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_forward_L.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(
            subject=subject, starting_time=younger_timepoint, ending_time=older_timepoint,
            user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
            config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
            oc=older_files[4], yas=younger_files[0], oas=older_files[0],
            f_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)

        with open(fr"{temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write)

        jobs_open = is_slurm_queue_open(slurm_user)
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = is_slurm_queue_open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)

        print(" \n")
        print(
            fr"Generating script {temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_forward_R.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(
            subject=subject, starting_time=younger_timepoint, ending_time=older_timepoint,
            user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
            config=config, yss=younger_files[3], oss=older_files[3], yc=younger_files[5],
            oc=older_files[5], yas=younger_files[1], oas=older_files[1],
            f_out=right_file_prefix, maxanat=max_anat, maxcp=max_cp)

        with open(fr"{temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write)

        jobs_open = is_slurm_queue_open(slurm_user)
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = is_slurm_queue_open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)

    elif mode == "reverse":
        output = path.join(
            output, fr"{subject}_{older_timepoint}_to_{younger_timepoint}")
        makedirs(output, exist_ok=True)
        left_file_prefix = fr"{output}/{subject}_L_{older_timepoint}-{younger_timepoint}."
        right_file_prefix = fr"{output}/{subject}_R_{older_timepoint}-{younger_timepoint}."

        print(" \n")
        print(
            fr"Generating script {temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_reverse_L.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(
            subject=subject, starting_time=older_timepoint, ending_time=younger_timepoint,
            user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
            config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
            oc=older_files[4], yas=younger_files[0], oas=older_files[0],
            r_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)

        with open(fr"{temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write)

        jobs_open = is_slurm_queue_open(slurm_user)
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = is_slurm_queue_open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)

        print(" \n")
        print(
            fr"Generating Script {temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        template_path = path.join(script_dir, "MSM_template_reverse_R.txt")
        with open(template_path, "r") as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(
            subject=subject, starting_time=older_timepoint, ending_time=younger_timepoint,
            user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
            config=config, yss=younger_files[3], oss=older_files[3], yc=younger_files[5],
            oc=older_files[5], yas=younger_files[1], oas=older_files[1],
            r_out=right_file_prefix, maxanat=max_anat, maxcp=max_cp)

        with open(fr"{temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write)

        jobs_open = is_slurm_queue_open(slurm_user)
        while jobs_open <= 0:
            print("no jobs open waiting 2 hours")
            sleep(2 * 3600)
            jobs_open = is_slurm_queue_open(slurm_user)
        print("Jobs open submitting script")
        run(fr"sbatch {temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)


# helper function for retriving subjects
def get_subjects(dataset: str):
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
    return subjects


# Function for MSM BL tp all
def run_msm_bl_To_all(dataset: str, alphanumeric_timepoints: bool, time_point_number_start_character: int,
                      output: str, starting_time: str, slurm_account: str, slurm_user: str,
                      slurm_email: str, levels: int, config: str,
                      max_anat: str, max_cp: str):

    subjects = get_subjects(dataset)
    print("\nAll subjects found. Beginning MSM")
    print('*' * 50)
    for subject in subjects:
        time_points = get_subject_time_points(
            dataset, subject, alphanumeric_timepoints, time_point_number_start_character, starting_time)
        if starting_time not in time_points:
            print(
                f"ERROR: Starting Time missing for {subject}! Proceeding to next subject")
            continue

        for time_point in time_points:
            if time_point != starting_time:
                run_msm(dataset, output, subject, starting_time, time_point, "forward",
                        levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user)
                run_msm(dataset, output, subject, starting_time, time_point, "reverse",
                        levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user)


# Function to run MSM on shirt time windows
def run_msm_short_time_windows(dataset: str, alphanumeric_timepoints: bool,
                               time_point_number_start_character: int,
                               output: str, slurm_account: str, slurm_user: str,
                               slurm_email: str, levels: int, config: str,
                               max_anat: str, max_cp: str, starting_time=None):
    subjects = get_subjects(dataset)
    print("\nAll subjects found. Beginning MSM")
    print('*' * 50)
    for subject in subjects:
        time_points = get_subject_time_points(
            dataset, subject, alphanumeric_timepoints, time_point_number_start_character, starting_time)
        for i, time_point in enumerate(time_points):
            if i + 1 >= len(time_points):
                break
            younger_time = time_point
            older_time = time_points[i + 1]
            run_msm(dataset, output, subject, younger_time, older_time, "forward",
                    levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user)
            run_msm(dataset, output, subject, older_time, younger_time, "reverse",
                    levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user)


# Function to run post processing on all subjects
def post_process_all(dataset: str, starting_time: str, resolution: str):
    for directory in listdir(dataset):
        full_path = path.join(dataset, directory)
        fields = directory.split("_")
        subject = fields[0]
        first_time = fields[1]
        second_time = fields[3]
        first_month = first_time[1:]
        second_month = second_time[2:]

        if first_time == starting_time:
            generate_post_processing_image(full_path,
                                           subject,
                                           first_time,
                                           second_time,
                                           resolution,
                                           "forward")

        elif second_time == starting_time:
            generate_post_processing_image(full_path,
                                           subject,
                                           first_time,
                                           second_time,
                                           resolution,
                                           "reverse")

        elif int(first_month) < int(second_month):
            generate_post_processing_image(full_path,
                                           subject,
                                           first_time,
                                           second_time,
                                           resolution,
                                           "forward")

        elif int(first_month) > int(second_month):
            generate_post_processing_image(full_path,
                                           subject,
                                           first_time,
                                           second_time,
                                           resolution,
                                           "reverse")


# Function to generate average maps
def generate_avg_maps(ciftify_dataset: str, msm_dataset: str, subject: str, younger_timepoint: str, older_timepoint: str, max_cp: str, max_anat: str):
    # create output for average maps
    msm_avg_output = path.join(
        msm_dataset, f"{subject}_{older_timepoint}_to_{younger_timepoint}_averaged")
    makedirs(msm_avg_output, exist_ok=True)

    # create variables for file locations from pre-msm
    younger_files = get_msm_files(ciftify_dataset, subject, younger_timepoint)
    older_files = get_msm_files(ciftify_dataset, subject, older_timepoint)
    left_younger_spherical_surface = younger_files[2]
    left_older_anatomical_surface = older_files[0]
    left_older_spherical_surface = older_files[2]
    right_younger_spherical_surface = younger_files[3]
    right_older_anatomical_surface = older_files[1]
    right_older_spherical_surface = older_files[3]

    # files for msm resverse registration
    msm_reverse_folder = path.join(
        msm_dataset, f"{subject}_{older_timepoint}_to_{younger_timepoint}")
    left_base_sphere_reverse = path.join(
        msm_reverse_folder, f"{subject}_L_{older_timepoint}-{younger_timepoint}.sphere.reg.surf.gii")
    left_cpgrid_sphere_reverse = path.join(
        msm_reverse_folder, f"{subject}_L_{older_timepoint}-{younger_timepoint}.sphere.CPgrid.reg.surf.gii")
    left_anatgrid_sphere_reverse = path.join(
        msm_reverse_folder, f"{subject}_L_{older_timepoint}-{younger_timepoint}.sphere.ANATgrid.reg.surf.gii")
    left_cpgrid_surfdist_reverse = path.join(
        msm_reverse_folder, f"{subject}_L_{older_timepoint}-{younger_timepoint}.surfdist.CPgrid.func.gii")
    left_anatgrid_surfdist_reverse = path.join(
        msm_reverse_folder, f"{subject}_L_{older_timepoint}-{younger_timepoint}.surfdist.ANATgrid.func.gii")
    right_base_sphere_reverse = path.join(
        msm_reverse_folder, f"{subject}_R_{older_timepoint}-{younger_timepoint}.sphere.reg.surf.gii")
    right_cpgrid_sphere_reverse = path.join(
        msm_reverse_folder, f"{subject}_R_{older_timepoint}-{younger_timepoint}.sphere.CPgrid.reg.surf.gii")
    right_anatgrid_sphere_reverse = path.join(
        msm_reverse_folder, f"{subject}_R_{older_timepoint}-{younger_timepoint}.sphere.ANATgrid.reg.surf.gii")
    right_cpgrid_surfdist_reverse = path.join(
        msm_reverse_folder, f"{subject}_R_{older_timepoint}-{younger_timepoint}.surfdist.CPgrid.func.gii")
    right_anatgrid_surfdist_reverse = path.join(
        msm_reverse_folder, f"{subject}_R_{older_timepoint}-{younger_timepoint}.surfdist.ANATgrid.func.gii")

    # files for msm forward registration
    msm_forward_folder = path.join(
        msm_dataset, f"{subject}_{younger_timepoint}_to_{older_timepoint}")
    left_base_sphere_forward = path.join(
        msm_forward_folder, f"{subject}_L_{younger_timepoint}-{older_timepoint}.sphere.reg.surf.gii")
    left_cpgrid_sphere_forward = path.join(
        msm_forward_folder, f"{subject}_L_{younger_timepoint}-{older_timepoint}.sphere.CPgrid.reg.surf.gii")
    left_anatgrid_sphere_forward = path.join(
        msm_forward_folder, f"{subject}_L_{younger_timepoint}-{older_timepoint}.sphere.ANATgrid.reg.surf.gii")
    left_cpgrid_surfdist_forward = path.join(
        msm_forward_folder, f"{subject}_L_{younger_timepoint}-{older_timepoint}.surfdist.CPgrid.func.gii")
    left_anatgrid_surfdist_forward = path.join(
        msm_forward_folder, f"{subject}_L_{younger_timepoint}-{older_timepoint}.surfdist.ANATgrid.func.gii")
    right_base_sphere_forward = path.join(
        msm_forward_folder, f"{subject}_R_{younger_timepoint}-{older_timepoint}.sphere.reg.surf.gii")
    right_cpgrid_sphere_forward = path.join(
        msm_forward_folder, f"{subject}_R_{younger_timepoint}-{older_timepoint}.sphere.CPgrid.reg.surf.gii")
    right_anatgrid_sphere_forward = path.join(
        msm_forward_folder, f"{subject}_R_{younger_timepoint}-{older_timepoint}.sphere.ANATgrid.reg.surf.gii")
    right_cpgrid_surfdist_forward = path.join(
        msm_forward_folder, f"{subject}_R_{younger_timepoint}-{older_timepoint}.surfdist.CPgrid.func.gii")
    right_anatgrid_surfdist_forward = path.join(
        msm_forward_folder, f"{subject}_R_{younger_timepoint}-{older_timepoint}.surfdist.ANATgrid.func.gii")

    # revfor sphere output names
    left_revfor_base_sphere = f"{msm_avg_output}/{subject}_L_{older_timepoint}-{younger_timepoint}.revfor.sphere.reg.surf.gii"
    right_revfor_base_sphere = f"{msm_avg_output}/{subject}_R_{older_timepoint}-{younger_timepoint}.revfor.sphere.reg.surf.gii"
    left_revfor_cpgrid_sphere = f"{msm_avg_output}/{subject}_L_{older_timepoint}-{younger_timepoint}.revfor.sphere.CPgrid.reg.surf.gii"
    right_revfor_cpgrid_sphere = f"{msm_avg_output}/{subject}_R_{older_timepoint}-{younger_timepoint}.revfor.sphere.CPgrid.reg.surf.gii"
    left_revfor_anatgrid_sphere = f"{msm_avg_output}/{subject}_L_{older_timepoint}-{younger_timepoint}.revfor.sphere.ANATgrid.reg.surf.gii"
    right_revfor_anatgrid_sphere = f"{msm_avg_output}/{subject}_R_{older_timepoint}-{younger_timepoint}.revfor.sphere.ANATgrid.reg.surf.gii"

    # avgfor sphere names
    left_avgfor_base_sphere = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.sphere.reg.surf.gii"
    right_avgfor_base_sphere = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.sphere.reg.surf.gii"
    left_avgfor_cpgrid_sphere = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.sphere.CPgrid.reg.surf.gii"
    right_avgfor_cpgrid_sphere = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.sphere.CPgrid.reg.surf.gii"
    left_avgfor_anatgrid_sphere = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.sphere.ANATgrid.reg.surf.gii"
    right_avgfor_anatgrid_sphere = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.sphere.ANATgrid.reg.surf.gii"

    # avgfor anat names
    left_avgfor_cpgrid_anat = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.anat.CPgrid.reg.surf.gii"
    right_avgfor_cpgrid_anat = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.anat.CPgrid.reg.surf.gii"
    left_avgfor_anatgrid_anat = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.anat.ANATgrid.reg.surf.gii"
    right_avgfor_anatgrid_anat = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.anat.ANATgrid.reg.surf.gii"

    # revfor surfdist names
    left_revfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_L_{older_timepoint}-{younger_timepoint}.revfor.surfdist.CPgrid.reg.surf.gii"
    left_revfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_L_{older_timepoint}-{younger_timepoint}.revfor.surfdist.ANATgrid.reg.surf.gii"
    right_revfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_R_{older_timepoint}-{younger_timepoint}.revfor.surfdist.CPgrid.reg.surf.gii"
    right_revfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_R_{older_timepoint}-{younger_timepoint}.revfor.surfdist.ANATgrid.reg.surf.gii"

    # angfor surfdist names
    left_avgfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.CPgrid.reg.surf.gii"
    left_avgfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.ANATgrid.reg.surf.gii"
    right_avgfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.CPgrid.reg.surf.gii"
    right_avgfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.ANATgrid.reg.surf.gii"

    # Generate Revfor spheres
    print("Begin generating revfor spheres")
    run(f"wb_command -surface-sphere-project-unproject {left_older_spherical_surface} {left_base_sphere_reverse} {left_younger_spherical_surface} {left_revfor_base_sphere}", shell=True)
    run(f"wb_command -surface-sphere-project-unproject {right_older_spherical_surface} {right_base_sphere_reverse} {right_younger_spherical_surface} {right_revfor_base_sphere}", shell=True)
    run(
        f"wb_command -surface-sphere-project-unproject {max_cp} {left_cpgrid_sphere_reverse} {max_cp} {left_revfor_cpgrid_sphere}", shell=True)
    run(
        f"wb_command -surface-sphere-project-unproject {max_cp} {right_cpgrid_sphere_reverse} {max_cp} {right_revfor_cpgrid_sphere}", shell=True)
    run(f"wb_command -surface-sphere-project-unproject {max_anat} {left_anatgrid_sphere_reverse} {max_anat} {left_revfor_anatgrid_sphere}", shell=True)
    run(f"wb_command -surface-sphere-project-unproject {max_anat} {right_anatgrid_sphere_reverse} {max_anat} {right_revfor_anatgrid_sphere}", shell=True)

    run(f"wb_command -surface-average {left_avgfor_base_sphere} -surf {left_base_sphere_forward} -surf {left_revfor_base_sphere}", shell=True)
    run(f"wb_command -surface-average {right_avgfor_base_sphere} -surf {right_base_sphere_forward} -surf {right_revfor_base_sphere}", shell=True)
    run(f"wb_command -surface-average {left_avgfor_cpgrid_sphere} -surf {left_cpgrid_sphere_forward} -surf {left_revfor_cpgrid_sphere}", shell=True)
    run(f"wb_command -surface-average {right_avgfor_cpgrid_sphere} -surf {right_cpgrid_sphere_forward} -surf {right_revfor_cpgrid_sphere}", shell=True)
    run(f"wb_command -surface-average {left_avgfor_anatgrid_sphere} -surf {left_anatgrid_sphere_forward} -surf {left_revfor_anatgrid_sphere}", shell=True)
    run(f"wb_command -surface-average {right_avgfor_anatgrid_sphere} -surf {right_anatgrid_sphere_forward} -surf {right_revfor_anatgrid_sphere}", shell=True)

    # Generate AvgFor Shpheres
    print("Begin generating avgfor spheres")
    run(
        f"wb_command -surface-modify-sphere -recenter {left_avgfor_base_sphere} 100 {left_avgfor_base_sphere}", shell=True)
    run(
        f"wb_command -surface-modify-sphere -recenter {right_avgfor_base_sphere} 100 {right_avgfor_base_sphere}", shell=True)
    run(
        f"wb_command -surface-modify-sphere -recenter {left_avgfor_cpgrid_sphere} 100 {left_avgfor_cpgrid_sphere}", shell=True)
    run(
        f"wb_command -surface-modify-sphere -recenter {right_avgfor_cpgrid_sphere} 100 {right_avgfor_cpgrid_sphere}", shell=True)
    run(
        f"wb_command -surface-modify-sphere -recenter {left_avgfor_anatgrid_sphere} 100 {left_avgfor_anatgrid_sphere}", shell=True)
    run(
        f"wb_command -surface-modify-sphere -recenter {right_avgfor_anatgrid_sphere} 100 {right_avgfor_anatgrid_sphere}", shell=True)

    # Generate AvgFor Anatomical Surfaces
    print("Begin generating avgfor surfaces")
    run(f"wb_command -surface-resample {left_older_anatomical_surface} {max_cp} {left_avgfor_cpgrid_sphere} BARYCENTRIC {left_avgfor_cpgrid_anat}", shell=True)
    run(f"wb_command -surface-resample {right_older_anatomical_surface} {max_cp} {right_avgfor_cpgrid_sphere} BARYCENTRIC {right_avgfor_cpgrid_anat}", shell=True)
    run(f"wb_command -surface-resample {left_older_anatomical_surface} {max_anat} {left_avgfor_anatgrid_sphere} BARYCENTRIC {left_avgfor_anatgrid_anat}", shell=True)
    run(f"wb_command -surface-resample {right_older_anatomical_surface} {max_anat} {right_avgfor_anatgrid_sphere} BARYCENTRIC {right_avgfor_anatgrid_anat}", shell=True)

    # Generate revfor surfdist
    print("Begin generating revfor surfdist")
    run(f"wb_command -metric-resample {left_cpgrid_surfdist_reverse} {left_cpgrid_sphere_reverse} {left_revfor_cpgrid_sphere} BARYCENTRIC {left_revfor_cpgrid_surfdist}", shell=True)
    run(f"wb_command -metric-resample {left_anatgrid_surfdist_reverse} {left_anatgrid_sphere_reverse} {left_revfor_anatgrid_sphere} BARYCENTRIC {left_revfor_anatgrid_surfdist}", shell=True)
    run(f"wb_command -metric-resample {right_cpgrid_surfdist_reverse} {right_cpgrid_sphere_reverse} {right_revfor_cpgrid_sphere} BARYCENTRIC {right_revfor_cpgrid_surfdist}", shell=True)
    run(f"wb_command -metric-resample {right_anatgrid_surfdist_reverse} {right_anatgrid_sphere_reverse} {right_revfor_anatgrid_sphere} BARYCENTRIC {right_revfor_anatgrid_surfdist}", shell=True)

    # calculate average surfdist
    print("begin calculating avgfor surfdists")
    run(f"wb_command -metric-math '(J1+J2)/2' {left_avgfor_cpgrid_surfdist} -var J1 {left_revfor_cpgrid_surfdist} -var J2 {left_cpgrid_surfdist_forward}", shell=True)
    run(f"wb_command -metric-math '(J1+J2)/2' {left_avgfor_anatgrid_surfdist} -var J1 {left_revfor_anatgrid_surfdist} -var J2 {left_anatgrid_surfdist_forward}", shell=True)
    run(f"wb_command -metric-math '(J1+J2)/2' {right_avgfor_cpgrid_surfdist} -var J1 {right_revfor_cpgrid_surfdist} -var J2 {right_cpgrid_surfdist_forward}", shell=True)
    run(f"wb_command -metric-math '(J1+J2)/2' {right_avgfor_anatgrid_surfdist} -var J1 {right_revfor_anatgrid_surfdist} -var J2 {right_anatgrid_surfdist_forward}", shell=True)
    run(f"wb_command -set-structure {left_avgfor_cpgrid_surfdist} CORTEX_LEFT")
    run(f"wb_command -set-structure {left_avgfor_anatgrid_surfdist} CORTEX_LEFT")
    run(f"wb_command -set-structure {right_avgfor_cpgrid_surfdist} CORTEX_RIGHT")
    run(f"wb_command -set-structure {right_avgfor_anatgrid_surfdist} CORTEX_RIGHT")
    print("complete\n")


def run_avg_maps_all(ciftify_dataset: str, msm_dataset: str, max_cp: str, max_anat: str, starting_time: str):
    print("\nBEGIN FUNCTION FOR AVG MAPS")
    print('*' * 50)
    for directory in listdir(msm_dataset):
        fields = directory.split("_")
        subject = fields[0]
        first_time = fields[1]
        second_time = fields[3]
        first_month = first_time[1:]
        second_month = second_time[1:]
        print(f"\nSubject: {subject}", f"First time pont and month: {first_time}/{first_month}",
              f"Second time point: {second_time}/{second_month}", sep="\n")
        if first_time == starting_time:
            continue
        elif second_time == starting_time:
            print(
                f"Beginning average maps for {subject} for times {second_month} to {first_month}")
            generate_avg_maps(ciftify_dataset, msm_dataset,
                              subject, second_time, first_time, max_cp, max_anat)
        elif second_month < first_month:
            print(
                f"Beginning average maps for {subject} for times {second_month} to {first_month}")
            generate_avg_maps(ciftify_dataset, msm_dataset,
                              subject, second_time, first_time, max_cp, max_anat)
        else:
            continue


"""
subjects_to_run = ['0021', '0031', '0056', '0059', '0069', '0072', '0074', '0106', '0112', '0113', '0120', '0127', '0142', '0150', '0156', '0173', '0205', '0210', '0229', '0259', '0296', '0298', '0303', '0359', '0377', '0382', '0384', '0413', '0416', '0419', '0454', '0473', '0498', '0553', '0555', '0602', '0605', '0618', '0626', '0668', '0677', '0679', '0680', '0731', '0734', '0746', '0751', '0767', '0800', '0802', '0908', '0925', '0934', '1016', '1032', '1052', '1074', '1098', '1122', '1155', '1169', '1261', '1280', '1286', '1300',
                   '1352', '1418', '1427', '2002', '2121', '2123', '2130', '2155', '2180', '2182', '2184', '2187', '2220', '2234', '2239', '2245', '2263', '2304', '2308', '2315', '2332', '2333', '2392', '2395', '4028', '4036', '4043', '4076', '4084', '4115', '4119', '4127', '4148', '4164', '4187', '4200', '4210', '4212', '4224', '4278', '4288', '4292', '4313', '4356', '4365', '4369', '4384', '4399', '4400', '4401', '4448', '4453', '4464', '4469', '4489', '4513', '4514', '4576', '4604', '4674', '4722', '4723', '4855', '4856', '4869', '4872', '4874', '4891']

subjects_dirs = get_ciftify_subject_list(
    '/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION',
    subjects_to_run,
    '.*_S_#_.*'
)

run_ciftify(
    '/N/project/ADNI_Processing/ADNI_FS6_ADSP/FINAL_FOR_EXTRACTION',
    subjects_dirs,
    '_',
    2,
    3,
    "/N/project/aMSM_AD/ADNI/HCP/TO_BE_PROCESSED_FIRST",
    "r00540",
    'sarigdon',
    'sarigdon@iu.edu'
)

run_msm_bl_To_all(
    r"/N/project/aMSM_AD/ADNI/HCP/TO_BE_PROCESSED_FIRST",
    True,
    1,
    r"/N/project/aMSM_AD/ADNI/HCP/MSM_T1W_ANATCONFIG",
    "BL",
    "r00540",
    "sarigdon",
    "sarigdon@iu.edu",
    6,
    r"/N/project/aMSM_AD/ADNI/HCP/configAnatGrid6",
    r"/N/project/aMSM_AD/ADNI/HCP/ico6sphere.LR.reg.surf.gii",
    r"/N/project/aMSM_AD/ADNI/HCP/ico5sphere.LR.reg.surf.gii"
)

run_msm_short_time_windows(
    r"/N/project/aMSM_AD/ADNI/HCP/TO_BE_PROCESSED_FIRST",
    True,
    1,
    r"/N/project/aMSM_AD/ADNI/HCP/MSM_T1W_ANATCONFIG",
    "r00540",
    "sarigdon",
    "sarigdon@iu.edu",
    6,
    r"/N/project/aMSM_AD/ADNI/HCP/configAnatGrid6",
    r"/N/project/aMSM_AD/ADNI/HCP/ico6sphere.LR.reg.surf.gii",
    r"/N/project/aMSM_AD/ADNI/HCP/ico5sphere.LR.reg.surf.gii",
    "BL"
)
"""

run_avg_maps_all(
    "/N/project/aMSM_AD/ADNI/HCP/TO_BE_PROCESSED_FIRST",
    "/N/project/aMSM_AD/ADNI/HCP/MSM_T1W_ANATCONFIG",
    "/N/project/aMSM_AD/ADNI/HCP/ico5sphere.LR.reg.surf.gii",
    "/N/project/aMSM_AD/ADNI/HCP/ico6sphere.LR.reg.surf.gii",
    "BL"
)
