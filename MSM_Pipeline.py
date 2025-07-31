#!/usr/bin/env python3

import argparse
import sys
from os import listdir, path, makedirs, remove
from re import compile
from subprocess import check_output, run
from time import sleep
from string import Template
from typing import Literal
from shutil import copy2
from datetime import datetime


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


log_path = path.expanduser(f'~/Scripts/MyScripts/Output/MSM_Pipeline/full_pipeline_log-{datetime.now()}.txt')
makedirs(path.dirname(log_path), exist_ok=True)
log_file = open(log_path, 'w+')
sys.stdout = Tee(sys.__stdout__, log_file)
sys.stderr = Tee(sys.__stderr__, log_file)
Mode = Literal["forward", "reverse", "average"]


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
    print (sorted(subjects_dirs))
    return sorted(subjects_dirs)


# Function to check number of slurm jobs remaining
def is_slurm_queue_open(slurm_user: str, job_limit: int=500):
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
    open_jobs = job_limit - jobs
    if open_jobs > 0:
        print(f"{open_jobs} jobs currently open")

    return open_jobs


# Function for running ciftify on list of subjects
def run_ciftify(dataset: str, directories: list, delimiter: str,
                subject_index: int, time_index: int, output_path: str, slurm_account: str,
                slurm_user: str, slurm_email: str, slurm_job_limit: int):
    print("\nStarting ciftify runs")
    print('*' * 50)
    user_home = path.expanduser('~')
    print(user_home)
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
        template_path = path.join(script_dir, "Templates", "Ciftify_template.txt")
        with open(template_path, 'r') as f:
            template_read = f.read()
        template = Template(template_read)
        to_write = template.substitute(subject=subject, time_point=time_point,
                                       account=slurm_account, email=slurm_email, dataset=dataset,
                                       output_dir=subject_output_path, dir=directory, user_home=user_home)

        with open(fr"{temp_output}/Subject_{subject}_{time_point}_recon_all.sh", 'w') as f:
            f.write(to_write)
        print(
            fr"Script wrote to {temp_output}/Subject_{subject}_{time_point}_recon_all.sh")

        jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
        while jobs_open <= 0:
            sleep(2 * 3600)
            jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
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
def get_subject_time_points(dataset: str, subject: str, alphanumeric_timepoints: bool=False, time_point_number_start_character: int | None=None, starting_time=None):
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


# Rescale Developmental surface


# Helper function for retriving MSM files
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


# Generate post processing images
def generate_post_processing_image(subject_directory: str, resolution: str, mode: Mode, output: str):
    # extreact info prom path
    subject_basename = path.basename(subject_directory)
    subject_basename_list = subject_basename.split("_")
    subject = subject_basename_list[0]
    starting_time = subject_basename_list[1]
    ending_time = subject_basename_list[3]
    
    # get all files for for post processing
    print("Locating Surfaces")
    if mode == "forward":
        left_younger_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.LYAS.{resolution}.surf.gii")
        right_younger_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.RYAS.{resolution}.surf.gii")
        left_older_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
        right_older_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
    elif mode == "reverse":
        left_younger_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
        right_younger_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.anat.{resolution}.reg.surf.gii")
        left_older_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.LOAS.{resolution}.surf.gii")
        right_older_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.ROAS.{resolution}.surf.gii")
    elif mode == "average":
        left_younger_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.LYAS.{resolution}.surf.gii")
        right_younger_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.RYAS.{resolution}.surf.gii")
        left_older_avg_surface = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.avgfor.anat.{resolution}.reg.surf.gii")
        right_older_avg_surface = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.avgfor.anat.{resolution}.reg.surf.gii")
        
    
    print("Locating Maps")
    if mode == "average":
        left_surface_map = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.avgfor.surfdist.{resolution}.reg.func.gii")
        right_surface_map = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.avgfor.surfdist.{resolution}.reg.func.gii")
    else:
        left_surface_map = path.join(
            subject_directory, f"{subject}_L_{starting_time}-{ending_time}.surfdist.{resolution}.func.gii")
        right_surface_map = path.join(
            subject_directory, f"{subject}_R_{starting_time}-{ending_time}.surfdist.{resolution}.func.gii")
    spec_file = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}_{resolution}.spec")
    
    # set palette
    print("Setting Palette")
    run(f"wb_command -metric-palette {left_surface_map} MODE_AUTO_SCALE -palette-name raich6_clrmid", shell=True)
    run(f"wb_command -metric-palette {right_surface_map} MODE_AUTO_SCALE -palette-name raich6_clrmid", shell=True)

    # add to spec file
    print("Adding to Spec File")
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_LEFT {left_younger_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_LEFT {left_older_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_LEFT {left_surface_map}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_RIGHT {right_younger_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_RIGHT {right_older_surface}", shell=True)
    run(f"wb_command -add-to-spec-file {spec_file} CORTEX_RIGHT {right_surface_map}", shell=True)

    # create scene file for auto scale
    print("Creating Auto Scale Scene")
    script_dir = path.dirname(path.realpath(__file__))
    if mode == "forward":
        template_path_auto_scale = path.join(
            script_dir, "Templates", "post_processing_template_forward.scene")
        template_path_set_scale = path.join(
            script_dir, "Templates", "post_processing_set_scale_template_forward.scene")
    elif mode == "reverse":
        template_path_auto_scale = path.join(
            script_dir, "Templates", "post_processing_template_reverse.scene")
        template_path_set_scale = path.join(
            script_dir, "Templates", "post_processing_set_scale_template_forward.scene")

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
        subject_directory, f"{subject}_{starting_time}-{ending_time}_{resolution}.scene")
    with open(template_auto_scale_output, "w+") as f:
        f.write(to_write_auto_scale)

    # create scene file for set scale
    print("Creating Set Scale Scene")
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
        subject_directory, f"{subject}_{starting_time}-{ending_time}_{resolution}_SET-SCALE.scene")
    with open(template_set_scale_output, "w+") as f:
        f.write(to_write_set_scale)

    # generate images
    print("Generating Images")
    scene_auto_scale = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}_{resolution}.scene")
    scene_set_scale = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}_{resolution}_SET-SCALE.scene")
    image_auto_scale = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}_{resolution}.png")
    image_set_scale = path.join(
        subject_directory, f"{subject}_{starting_time}-{ending_time}_{resolution}SET-SCALE.png")
    run(f"wb_command -show-scene {scene_auto_scale} 1 {image_auto_scale} 1024 512", shell=True)
    run(f"wb_command -show-scene {scene_set_scale} 1 {image_set_scale} 1024 512", shell=True)

    print("Copying Imagesd to Output")
    copy2(image_auto_scale, output)
    copy2(image_set_scale, output)


# Function for running MSM commands
def run_msm(dataset: str, output: str, subject: str, younger_timepoint: str,
            older_timepoint: str, mode: Mode, is_local: bool=False, levels: int=6, config: str | None=None,
            max_anat: str | None=None, max_cp: str | None=None, slurm_email: str | None=None,
            slurm_account: str | None=None, slurm_user: str | None=None, slurm_job_limit: int | None=None):

    user_home = path.expanduser('~')
    if config == None:
        config = path.join(user_home, "bin", "NeededFiles", "ConfigAnatGrid6")
    if max_anat == None:
        max_anat = path.join(user_home, "bin", "NeededFiles", "ico6sphere.LR.reg.surf.gii")
    if max_cp == None:
        max_cp = path.join(user_home, "bin", "NeededFiles", "ico5sphere.LR.reg.surf.gii")
    
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
        output = path.join(output, fr"{subject}_{younger_timepoint}_to_{older_timepoint}")
        makedirs(output, exist_ok=True)
        left_file_prefix = fr"{output}/{subject}_L_{younger_timepoint}-{older_timepoint}."
        right_file_prefix = fr"{output}/{subject}_R_{younger_timepoint}-{older_timepoint}."

        print(" \n")
        print(fr"Generating script file {temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        
        # Templates for remote run (default)
        if not is_local:
            # left hemisphere
            template_path_l = path.join(script_dir, "Templates", "MSM_template_forward_L.txt")
            with open(template_path_l, "r") as f:
                template_read_l = f.read()
            template_l = Template(template_read_l)
            to_write_l = template_l.substitute(
                subject=subject, starting_time=younger_timepoint, ending_time=older_timepoint,
                user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
                config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                f_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
            
            # right hemisphere
            template_path_r = path.join(script_dir, "Templates", "MSM_template_forward_R.txt")
            with open(template_path_r, "r") as f:
                template_read_r = f.read()
            template_r = Template(template_read_r)
            to_write_r = template_r.substitute(
                subject=subject, starting_time=younger_timepoint, ending_time=older_timepoint,
                user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
                config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                f_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
            
        # Templates for local run
        elif is_local:
            # left hemisphere
            template_path_l = path.join(script_dir, "Templates", "MSM_template_forward_L_local.txt")
            with open(template_path_l, "r") as f:
                template_read_l = f.read()
            template_l = Template(template_read_l)
            to_write_l = template_l.substitute(
                levels=levels, config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                f_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
            
            # right hemisphere
            template_path_r = path.join(script_dir, "Templates", "MSM_template_forward_R_local.txt")
            with open(template_path_r, "r") as f:
                template_read_r = f.read()
            template_r = Template(template_read_r)
            to_write_r = template_r.substitute(
                levels=levels, config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                f_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
            
        with open(fr"{temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write_l)
        with open(fr"{temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write_r)

        # submit remote jobs
        if not is_local:
            #left hemisphere
            if slurm_job_limit == None:
                jobs_open = is_slurm_queue_open(slurm_user)
            else:
                jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            while jobs_open <= 0:
                print("no jobs open waiting 2 hours")
                sleep(2 * 3600)
                if slurm_job_limit == None:
                    jobs_open = is_slurm_queue_open(slurm_user)
                else:
                    jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            print("Jobs open submitting script")
            run(fr"sbatch {temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh")
            
            #right hemisphere
            if slurm_job_limit == None:
                jobs_open = is_slurm_queue_open(slurm_user)
            else:
                jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            
            while jobs_open <= 0:
                print("no jobs open waiting 2 hours")
                sleep(2 * 3600)
                if slurm_job_limit == None:
                    jobs_open = is_slurm_queue_open(slurm_user)
                else:
                    jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            print("Jobs open submitting script")
            run(fr"sbatch {temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh")
        
         # run lcoal job        
        elif is_local:
            run(fr"bash {temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_L_{younger_timepoint}-{older_timepoint}_MSM.sh")
            run(fr"bash {temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_R_{younger_timepoint}-{older_timepoint}_MSM.sh")

    elif mode == "reverse":
        output = path.join(
            output, fr"{subject}_{older_timepoint}_to_{younger_timepoint}")
        makedirs(output, exist_ok=True)
        left_file_prefix = fr"{output}/{subject}_L_{older_timepoint}-{younger_timepoint}."
        right_file_prefix = fr"{output}/{subject}_R_{older_timepoint}-{younger_timepoint}."
        print(" \n")
        print(fr"Generating script {temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh")
        script_dir = path.dirname(path.realpath(__file__))
        # Templates for remote jobs
        if not is_local:
            #left hemisphere
            template_path_l = path.join(script_dir, "Templates", "MSM_template_reverse_L.txt")
            with open(template_path_l, "r") as f:
                template_read_l = f.read()
            template_l = Template(template_read_l)
            to_write_l = template_l.substitute(
                subject=subject, starting_time=older_timepoint, ending_time=younger_timepoint,
                user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
                config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                r_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
            
            #right hemisphere
            template_path_r = path.join(script_dir, "Templates", "MSM_template_reverse_R.txt")
            with open(template_path_r, "r") as f:
                template_read_r = f.read()
            template_r = Template(template_read_r)
            to_write_r = template_r.substitute(
                subject=subject, starting_time=older_timepoint, ending_time=younger_timepoint,
                user_home=user_home, email=slurm_email, account=slurm_account, levels=levels,
                config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                r_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
            
        # Templates for local jobs
        elif is_local:
            # left_hemisphere
            template_path_l = path.join(script_dir, "Templates", "MSM_template_reverse_L_local.txt")
            with open(template_path_l, "r") as f:
                template_read_l = f.read()
            template_l = Template(template_read_l)
            to_write_l = template_l.substitute(
                levels=levels, config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                r_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
            
            # right_hemisphere
            template_path_r = path.join(script_dir, "Templates", "MSM_template_reverse_R_local.txt")
            with open(template_path_r, "r") as f:
                template_read_r = f.read()
            template_r = Template(template_read_r)
            to_write_r = template_r.substitute(
                levels=levels, config=config, yss=younger_files[2], oss=older_files[2], yc=younger_files[4],
                oc=older_files[4], yas=younger_files[0], oas=older_files[0],
                r_out=left_file_prefix, maxanat=max_anat, maxcp=max_cp)
        with open(fr"{temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write_l)
        with open(fr"{temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh", "w+") as f:
            f.write(to_write_r)
         
        # Submit remote jobs
        if not is_local:
            # Left hemisphere
            if slurm_job_limit == None:
                jobs_open = is_slurm_queue_open(slurm_user)
            else:
                jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            
            while jobs_open <= 0:
                print("no jobs open waiting 2 hours")
                sleep(2 * 3600)
                if slurm_job_limit == None:
                    jobs_open = is_slurm_queue_open(slurm_user)
                else:
                    jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            print("Jobs open submitting script")
            run(fr"sbatch {temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh")
            
            # Right hemisphere
            if slurm_job_limit == None:
                jobs_open = is_slurm_queue_open(slurm_user)
            else:
                jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            
            while jobs_open <= 0:
                print("no jobs open waiting 2 hours")
                sleep(2 * 3600)
                if slurm_job_limit == None:
                    jobs_open = is_slurm_queue_open(slurm_user)
                else:
                    jobs_open = is_slurm_queue_open(slurm_user, slurm_job_limit)
            print("Jobs open submitting script")
            run(fr"sbatch {temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh")

        # Run local jobs
        if is_local:
            run(fr"bash {temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_L_{older_timepoint}-{younger_timepoint}_MSM.sh")
            run(fr"bash {temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh", shell=True)
            remove(fr"{temp_output}/Subject_{subject}_R_{older_timepoint}-{younger_timepoint}_MSM.sh")
            

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


# Function for MSM BL to all
def run_msm_bl_to_all(dataset: str, alphanumeric_timepoints: bool, time_point_number_start_character: int,
                      output: str, starting_time: str, slurm_account: str, slurm_user: str,
                      slurm_email: str, slurm_job_limit: int | None=None, levels: int=6, config: str | None=None,
                      max_anat: str | None=None, max_cp: str | None=None):

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
                        levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user, slurm_job_limit)
                run_msm(dataset, output, subject, starting_time, time_point, "reverse",
                        levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user, slurm_job_limit)


# Function to run MSM on shirt time windows
def run_msm_short_time_windows(dataset: str, alphanumeric_timepoints: bool,
                               time_point_number_start_character: int,
                               output: str, slurm_account: str, slurm_user: str,
                               slurm_email: str, slurm_job_limit: int | None=None, levels: int=6, 
                               config: str | None=None, max_anat: str | None=None, max_cp: str | None=None,
                               starting_time: str | None=None):
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
            if younger_time != starting_time and older_time != starting_time:
                run_msm(dataset, output, subject, younger_time, older_time, "forward",
                        levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user, slurm_job_limit)
                run_msm(dataset, output, subject, younger_time, older_time, "reverse",
                        levels, config, max_anat, max_cp, slurm_email, slurm_account, slurm_user, slurm_job_limit)


# Function to run post processing on all subjects
def post_process_all(dataset: str, starting_time: str, resolution: str, output: str):
    for directory in listdir(dataset):
        full_path = path.join(dataset, directory)
        fields = directory.split("_")
        subject = fields[0]
        first_time = fields[1]
        second_time = fields[3]
        first_month = first_time[1:]
        second_month = second_time[2:]
        subject_output = path.join(output, subject)
        makedirs(subject_output, exist_ok=True)
        print("*" * 50)
        print("Begin Post Processing at {resolution} resolution")
        print("*" * 50)
        print(
            f"Path: {full_path}\nSubject: {subject}\nTime1: {first_time}\nTime2: {second_time}\nOutput: {subject_output}")
        if first_time == starting_time:
            print("Mode: Forward")
            generate_post_processing_image(full_path,
                                           resolution,
                                           "forward",
                                           subject_output)

        elif second_time == starting_time:
            print("Mode: Reverse")
            generate_post_processing_image(full_path,
                                           resolution,
                                           "reverse",
                                           subject_output)

        elif int(first_month) < int(second_month):
            print("Mode: Forward")
            generate_post_processing_image(full_path,
                                           resolution,
                                           "forward",
                                           subject_output)

        elif int(first_month) > int(second_month):
            print("Mode: Reverse")
            generate_post_processing_image(full_path,
                                           resolution,
                                           "reverse",
                                           subject_output)


# Function to generate post processing for average maps
def post_process_avg(dataset: str, starting_time: str, resolution: str, output: str):
    for directory in listdir(dataset):
        full_path = path.join(dataset, directory)
        fields = directory.split("_")
        subject = fields[0]
        first_time = fields[1]
        second_time = fields[3]
        first_month = first_time[1:]
        second_month = second_time[2:]
        subject_output = path.join(output, subject)
        makedirs(subject_output, exist_ok=True)
        print("*" * 50)
        print("Begin Post Processing at {resolution} resolution")
        print("*" * 50)
        print(
            f"Path: {full_path}\nSubject: {subject}\nTime1: {first_time}\nTime2: {second_time}\nOutput: {subject_output}")
        if first_time == starting_time:
            print("Mode: Average")
            generate_post_processing_image(full_path,
                                           resolution,
                                           "average",
                                           subject_output)

        elif second_time == starting_time:
            continue

        elif int(first_month) < int(second_month):
            print("Mode: Average")
            generate_post_processing_image(full_path,
                                           resolution,
                                           "average",
                                           subject_output)

        elif int(first_month) > int(second_month):
           continue


# Function to generate average maps
def generate_avg_maps(ciftify_dataset: str, msm_dataset: str, subject: str, younger_timepoint: str, older_timepoint: str, max_cp: str, max_anat: str):
    # create output for average maps
    msm_avg_output = path.join(
        msm_dataset, f"{subject}_{older_timepoint}_to_{younger_timepoint}")
    makedirs(msm_avg_output, exist_ok=True)

    # create variables for file locations from pre-msm
    younger_files = get_msm_files(ciftify_dataset, subject, younger_timepoint)
    older_files = get_msm_files(ciftify_dataset, subject, older_timepoint)
    left_younger_spherical_surface = younger_files[2]
    left_older_spherical_surface = older_files[2]
    right_younger_spherical_surface = younger_files[3]
    right_older_spherical_surface = older_files[3]

    # files for msm resverse registration
    msm_reverse_folder = path.join(
        msm_dataset, f"{subject}_{older_timepoint}_to_{younger_timepoint}")
    left_older_anatomical_surface_cpgrid = path.join(
        msm_reverse_folder, f"{subject}_L_{older_timepoint}-{younger_timepoint}.LOAS.CPgrid.surf.gii")
    left_older_anatomical_surface_anatgrid = path.join(
        msm_reverse_folder, f"{subject}_L_{older_timepoint}-{younger_timepoint}.LOAS.ANATgrid.surf.gii")
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
    right_older_anatomical_surface_cpgrid = path.join(
        msm_reverse_folder, f"{subject}_R_{older_timepoint}-{younger_timepoint}.ROAS.CPgrid.surf.gii")
    right_older_anatomical_surface_anatgrid = path.join(
        msm_reverse_folder, f"{subject}_R_{older_timepoint}-{younger_timepoint}.ROAS.ANATgrid.surf.gii")
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
    left_revfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_L_{older_timepoint}-{younger_timepoint}.revfor.surfdist.CPgrid.reg.func.gii"
    left_revfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_L_{older_timepoint}-{younger_timepoint}.revfor.surfdist.ANATgrid.reg.func.gii"
    right_revfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_R_{older_timepoint}-{younger_timepoint}.revfor.surfdist.CPgrid.reg.func.gii"
    right_revfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_R_{older_timepoint}-{younger_timepoint}.revfor.surfdist.ANATgrid.reg.func.gii"

    # angfor surfdist names
    left_avgfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.CPgrid.reg.func.gii"
    left_avgfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_L_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.ANATgrid.reg.func.gii"
    right_avgfor_cpgrid_surfdist = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.CPgrid.reg.func.gii"
    right_avgfor_anatgrid_surfdist = f"{msm_avg_output}/{subject}_R_{younger_timepoint}-{older_timepoint}.avgfor.surfdist.ANATgrid.reg.func.gii"

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

    # Generate RevFor Anatomical Surfaces
    print("Begin generating revfor surfaces")
    run(f"wb_command -surface-resample {left_older_anatomical_surface_cpgrid} {max_cp} {left_avgfor_cpgrid_sphere} \"BARYCENTRIC\" {left_avgfor_cpgrid_anat}", shell=True)
    run(f"wb_command -surface-resample {right_older_anatomical_surface_cpgrid} {max_cp} {right_avgfor_cpgrid_sphere} \"BARYCENTRIC\" {right_avgfor_cpgrid_anat}", shell=True)
    run(f"wb_command -surface-resample {left_older_anatomical_surface_anatgrid} {max_anat} {left_avgfor_anatgrid_sphere} \"BARYCENTRIC\" {left_avgfor_anatgrid_anat}", shell=True)
    run(f"wb_command -surface-resample {right_older_anatomical_surface_anatgrid} {max_anat} {right_avgfor_anatgrid_sphere} \"BARYCENTRIC\" {right_avgfor_anatgrid_anat}", shell=True)

    # Generate revfor surfdist
    print("Begin generating revfor surfdist")
    run(f"wb_command -metric-resample {left_cpgrid_surfdist_reverse} {left_cpgrid_sphere_reverse} {left_revfor_cpgrid_sphere} \"BARYCENTRIC\" {left_revfor_cpgrid_surfdist}", shell=True)
    run(f"wb_command -metric-resample {left_anatgrid_surfdist_reverse} {left_anatgrid_sphere_reverse} {left_revfor_anatgrid_sphere} \"BARYCENTRIC\" {left_revfor_anatgrid_surfdist}", shell=True)
    run(f"wb_command -metric-resample {right_cpgrid_surfdist_reverse} {right_cpgrid_sphere_reverse} {right_revfor_cpgrid_sphere} \"BARYCENTRIC\" {right_revfor_cpgrid_surfdist}", shell=True)
    run(f"wb_command -metric-resample {right_anatgrid_surfdist_reverse} {right_anatgrid_sphere_reverse} {right_revfor_anatgrid_sphere} \"BARYCENTRIC\" {right_revfor_anatgrid_surfdist}", shell=True)

    # calculate average surfdist
    print("begin calculating avgfor surfdists")
    run(f"wb_command -metric-math '(J1+J2)/2' {left_avgfor_cpgrid_surfdist} -var J1 {left_revfor_cpgrid_surfdist} -var J2 {left_cpgrid_surfdist_forward}", shell=True)
    run(f"wb_command -metric-math '(J1+J2)/2' {left_avgfor_anatgrid_surfdist} -var J1 {left_revfor_anatgrid_surfdist} -var J2 {left_anatgrid_surfdist_forward}", shell=True)
    run(f"wb_command -metric-math '(J1+J2)/2' {right_avgfor_cpgrid_surfdist} -var J1 {right_revfor_cpgrid_surfdist} -var J2 {right_cpgrid_surfdist_forward}", shell=True)
    run(f"wb_command -metric-math '(J1+J2)/2' {right_avgfor_anatgrid_surfdist} -var J1 {right_revfor_anatgrid_surfdist} -var J2 {right_anatgrid_surfdist_forward}", shell=True)
    run(f"wb_command -set-structure {left_avgfor_cpgrid_surfdist} CORTEX_LEFT", shell=True)
    run(f"wb_command -set-structure {left_avgfor_anatgrid_surfdist} CORTEX_LEFT", shell=True)
    run(f"wb_command -set-structure {right_avgfor_cpgrid_surfdist} CORTEX_RIGHT", shell=True)
    run(f"wb_command -set-structure {right_avgfor_anatgrid_surfdist} CORTEX_RIGHT", shell=True)
    print("complete\n")


# Function to run all average maps
def generate_avg_maps_all(ciftify_dataset: str, msm_dataset: str, max_cp: str, max_anat: str, starting_time: str):
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
            continue
        else:
            continue


# Command line interface
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run MSM Pipeline Functions", usage="MSM_Pipeline.py [-h] <command> [<args>]")
    subparser = parser.add_subparsers(dest="command", required=True)
    
    # Get Ciftify Subject List
    csl = subparser.add_parser("get_ciftify_subject_list", help="Retrieve list of subejcts for Ciftify")
    csl.add_argument("--dataset", required=True, help="Path to data that needs to be ran through ciftify")
    csl.add_argument("--subjects", nargs='+', required=True, help="List of subject IDs space seperated")
    csl.add_argument("--pattern", required=True, help="Regex template of directory names using # as a stand-in for the subject ID. ie '.*_S_#_.*")

    # Is Slurm Queue Open
    sqo = subparser.add_parser("is_slurm_queue_open", help="Check how many open jobs are avaliable for the indicated user")
    sqo.add_argument("--slurm_user", required=True, help="The account name of the Slurm user to check")
    sqo.add_argument("--slurm_job_limit", required=True, help="The users Slurm job limit")

    # Run Ciftify
    rc = subparser.add_parser("run_ciftify", help="Run ciftify-recon-all on the indicated directories and palce them in the indicated output")
    rc.add_argument("--dataset", required=True, help="Path to data that needs to be ran through ciftify")
    rc.add_argument("--directories", nargs='+', required=True, help="List of directories to run space seperated")
    rc.add_argument("--delimiter", required=True, help="Delimiiter used in directory names to seperate fields")
    rc.add_argument("--subject_index", required=True, type=int, help="Index of subject ID based on delimiter")
    rc.add_argument("--time_index", required=True, type=int, help="Index of time point based on delimeter")
    rc.add_argument("--output_path", required=True, help="Path to output of the command, must be empty")
    rc.add_argument("--slurm_account", required=True, help="Slurm account ID for submission")
    rc.add_argument("--slurm_user", required=True, help="Slurm username for checking queue")
    rc.add_argument("--slurm_email", required=True, help="Email for failed jobs to send to")
    rc.add_argument("--slurm_job_limit", required=True, help="The users Slurm job limit")

    # Get Subject Time Points
    gst = subparser.add_parser("get_subject_time_points", help="Retrieve list of time points based on subejct")
    gst.add_argument("--dataset", required=True, help="Path to directory containing subject data")
    gst.add_argument("--subject", required=True, help="The subject ID to retrieve time points for")
    gst.add_argument("--alphanumeric_timepoints", action="store_true", help="Use if the timepoints are alphanumeric")
    gst.add_argument("--time_point_number_start_character", required=False, type=int, help="The character where numbers begin in the timepoint 0 indexed, only required if using --alphanumeric_timepoints")
    gst.add_argument("--starting_time", required=False, help="Used if the starting time point uses a different naming convnetion")

    # Generate Post Processing Image
    gppi = subparser.add_parser("generate_post_processing_image", help="Generate post-processing scene and image for one subject")
    gppi.add_argument("--subject_directory", required=True, help="Path to directory containing MSM files for images you wish to create")
    gppi.add_argument("--resolution", choices=["CPgrid", "ANATgrid"], required=True, help="Resolution of registration for image creation, either CPgrid or ANATgrid")
    gppi.add_argument("--mode", choices=["forward", "reverse", "average"], required=True, help="Either forward or reverse dependant on registration")
    gppi.add_argument("--output", required=True, help="Location to copy the images to, will always place them in the subject directory as well")

    # Run MSM
    rm = subparser.add_parser("run_msm", help="Run MSM on the indicated subject and time points in the indicated direction")
    rm.add_argument("--dataset", required=True, help="Path to directory containing all time points for registration")
    rm.add_argument("--output", required=True, help="Path for output of MSM files, a folder for each registration will be created here")
    rm.add_argument("--subject", required=True, help="The subject ID MSM registration")
    rm.add_argument("--younger_timepoint", required=True, help="The younger time point for registration")
    rm.add_argument("--older_timepoint", required=True, help="The older time point for registration")
    rm.add_argument("--mode", choices=["forward", "reverse"], required=True, help="The registration mode, either forward or reverse")
    rm.add_argument("--is_local", action="store_true", help="Used to make MSM run in a local environment")
    rm.add_argument("--levels",required=False, type=int, default=6, help="Levels of MSM to run, see documentation for more information. Defaults to 6")
    rm.add_argument("--config", required=False, help="Path to MSM config file to use, see MSM documentation for more information. Only needed if not using default config")
    rm.add_argument("--max_anat", required=False, help="Path to MaxAnat reference sphere, typically ico6sphere. Only needed if not using default sphere")
    rm.add_argument("--max_cp", required=False, help="Path to MaxCP reference sphere, typically ico5sphere. Only needed if not using default sphere")
    rm.add_argument("--slurm_email", required=False, help="Email for failed jobs to send to. Only needed for remote jobs")
    rm.add_argument("--slurm_account", required=False, help="Slurm account ID for submission. Only needed for remote jobs")
    rm.add_argument("--slurm_user", required=False, help="Slurm username for checking queue. Only needed for remote jobs")
    rm.add_argument("--slurm_job_limit", required=False, help="The users Slurm job limit. Only needed for remote jobs, and if the slurm job limit is not 500")

    # Run MSM BL to All
    rmba = subparser.add_parser("run_msm_bl_to_all", help="Run MSM from baseline to all time points, both forward and reverse")
    rmba.add_argument("--dataset", required=True, help="Path to directory containing all data for registration")
    rmba.add_argument("--alphanumeric_timepoints", required=True, help="If the time points are alphanumeric")
    rmba.add_argument("--time_point_number_start_character", required=True, type=int, help="the character where numbers begin in the timepoint 0 indexed")
    rmba.add_argument("--output", required=True, help="Path for output of MSM files, a folder for each registration will be created here")
    rmba.add_argument("--starting_time", required=True, help="The time point used as baseline or 'bl' for all registrations")
    rmba.add_argument("--slurm_account", required=True, help="Slurm account ID for submission")
    rmba.add_argument("--slurm_user", required=True, help="Slurm username for checking queue")
    rmba.add_argument("--slurm_email", required=True, help="Email for failed jobs to send to")
    rmba.add_argument("--slurm_job_limit", required=False, help="The users Slurm job limit. Only needed if the slurm job limit is not 500")
    rmba.add_argument("--levels",required=False, type=int, default=6, help="Levels of MSM to run, see documentation for more information, defaults to 6")
    rmba.add_argument("--config", required=False, help="Path to MSM config file to use, see MSM documentation for more information. Only needed if not using default config")
    rmba.add_argument("--max_anat", required=False, help="Path to MaxAnat reference sphere, typically ico6sphere. Only needed if not using default sphere")
    rmba.add_argument("--max_cp", required=False, help="Path to MaxCP reference sphere, typically ico5sphere. Only needed if not using default sphere")

    # Run MSM Short Time Windows
    rmst = subparser.add_parser("run_msm_short_time_windows", help="Run MSM on sequential time points, both forward and reverse")
    rmst.add_argument("--dataset", required=True, help="Path to directory containing all data for registration")
    rmst.add_argument("--alphanumeric_timepoints", required=True, help="If the time points are alphanumeric")
    rmst.add_argument("--time_point_number_start_character", required=True, type=int, help="the character where numbers begin in the timepoint 0 indexed")
    rmst.add_argument("--output", required=True, help="Path for output of MSM files, a folder for each registration will be created here")
    rmst.add_argument("--slurm_account", required=True, help="Slurm account ID for submission")
    rmst.add_argument("--slurm_user", required=True, help="Slurm username for checking queue")
    rmst.add_argument("--slurm_email", required=True, help="Email for failed jobs to send to")
    rmst.add_argument("--slurm_job_limit", required=False, help="The users Slurm job limit. Only needed if slurm job limit is not 500")
    rmst.add_argument("--levels",required=False, type=int, default=6, help="Levels of MSM to run, see documentation for more information, defaults to 6")
    rmst.add_argument("--config", required=False, help="Path to MSM config file to use, see MSM documentation for more information. Only needed if not using default config")
    rmst.add_argument("--max_anat", required=False, help="Path to MaxAnat reference sphere, typically ico6sphere. Only needed if not using default sphere")
    rmst.add_argument("--max_cp", required=False, help="Path to MaxCP reference sphere, typically ico5sphere. Only needed if not using default sphere")
    rmst.add_argument("--starting_time", required=False, help="The starting time point. Only used if you want to skip baseline registrations")

    # Post Process All
    ppa = subparser.add_parser("post_process_all", help="Generatee Post Processing images for all MSM registrations")
    ppa.add_argument("--dataset", required=True, help="Loaction of MSM registrations")
    ppa.add_argument("--starting_time", required=True, help="Basline timepoint of data, used to determine if forward or reverse registration was used")
    ppa.add_argument("--resolution", choices=["CPgrid", "ANATgrid"], required=True, help="Resolution of registration for image creation, either CPgrid or ANATgrid")
    ppa.add_argument("--output", required=True, help="Location to copy the images to, will always place them in the subject directory as well")
    
    # Post Process Avg
    ppavg = subparser.add_parser("post_process_avg")
    ppavg.add_argument("--dataset", required=True, help="Loaction of MSM registrations")
    ppavg.add_argument("--starting_time", required=True, help="Basline timepoint of data, used to determine if forward or reverse registration was used")
    ppavg.add_argument("--resolution", choices=["CPgrid", "ANATgrid"], required=True, help="Resolution of registration for image creation, either CPgrid or ANATgrid")
    ppavg.add_argument("--output", required=True, help="Location to copy the images to, will always place them in the subject directory as well")

    # Generate Avg Maps
    gam = subparser.add_parser("generate_avg_maps", help="Generate average maps for one subject")
    gam.add_argument("--ciftify_dataset", required=True, help="Path to data from ciftify run")
    gam.add_argument("--msm_dataset", required=True, help="Path to MSM registrations")
    gam.add_argument("--subject", required=True, help="Subject ID to generate average maps")
    gam.add_argument("--younger_timepoint", required=True, help="The younger time point of the registration")
    gam.add_argument("--older_timepoint", required=True, help="The older time point of the registration")
    gam.add_argument("--max_cp", required=True, help="Path to MaxCP reference sphere, typically ico5sphere")
    gam.add_argument("--max_anat", required=True, help="Path to MaxANAT reference sphere, typically ico6sphere")
        
    # Generate All Avg Maps
    raa = subparser.add_parser("generate_avg_maps_all", help="Run average map generation on all subjects")
    raa.add_argument("--ciftify_dataset", required=True, help="Path to data from ciftify run")
    raa.add_argument("--msm_dataset", required=True, help="Path to MSM registrations")
    raa.add_argument("--max_cp", required=True, help="Path to MaxCP reference sphere, typically ico5sphere")
    raa.add_argument("--max_anat", required=True, help="Path to MaxANAT reference sphere, typically ico6sphere")
    raa.add_argument("--starting_time", required=True, help="Basleine of registrations, used to determine which avg maps are needed")

    args = parser.parse_args()
    
    if args.command == "get_ciftify_subject_list":
        args_dict = vars(args)
        args_dict.pop("command", None)
        get_ciftify_subject_list(**args_dict)
    elif args.command == "is_slurm_queue_open":
        args_dict = vars(args)
        args_dict.pop("command", None)
        is_slurm_queue_open(**args_dict)
    elif args.command == "run_ciftify":
        args_dict = vars(args)
        args_dict.pop("command", None)
        run_ciftify(**args_dict)
    elif args.command == "get_subject_time_points":
        args_dict = vars(args)
        args_dict.pop("command", None)
        get_subject_time_points(**args_dict)
    elif args.command == "generate_post_processing_image":
        args_dict = vars(args)
        args_dict.pop("command", None)
        generate_post_processing_image(**args_dict)
    elif args.command == "run_msm":
        args_dict = vars(args)
        args_dict.pop("command", None)
        run_msm(**args_dict)
    elif args.command == "run_msm_bl_to_all":
        args_dict = vars(args)
        args_dict.pop("command", None)
        run_msm_bl_to_all(**args_dict)
    elif args.command == "run_msm_short_time_windows":
        args_dict = vars(args)
        args_dict.pop("command", None)
        run_msm_short_time_windows(**args_dict)
    elif args.command == "post_process_all":
        args_dict = vars(args)
        args_dict.pop("command", None)
        post_process_all(**args_dict)
    elif args.command == "post_process_avg":
        args_dict = vars(args)
        args_dict.pop("command", None)
        post_process_avg(**args_dict)
    elif args.command == "generate_avg_maps":
        args_dict = vars(args)
        args_dict.pop("command", None)
        generate_avg_maps(**args_dict)
    elif args.command == "generate_avg_maps_all":
        args_dict = vars(args)
        args_dict.pop("command", None)
        generate_avg_maps_all(**args_dict)
