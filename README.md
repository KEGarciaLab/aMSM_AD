<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Issues][issues-shield]][issues-url]
[![Stars][stars-shield]][stars-url]


<h3 align="center">aMSM_AD</h3>

  <p align="center">
    Processing scripts for aMSM analysis of Alzheimer's Disease data
    <br />
    <a href="https://github.com/KEGarciaLab/aMSM_AD"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/KEGarciaLab/aMSM_AD/issues">Report Bug</a>
    ·
    <a href="https://github.com/KEGarciaLab/aMSM_AD/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## About The Project

Processing scripts for aMSM analysis of Alzheimer's Disease data.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- GETTING STARTED -->
## Getting Started

To get started with using these tools for the instructions below to install them.


### Installation

All scripts used for installation of the various tools can be found in the Installation folder of the repo. They should be ran in the order listed below to avoid errors. It is also recommended that you either reboot your system or reconnect through an ssh after each installation to ensure it was completed properly. Finally, these installation scripts were made assuming this would be ran on one of the IU supercomputing clusters. If you are outside of IU or are not using one of these systems you will need to install MSM, Ciftify, and Conetome Workbench manually, including updating `.bash_profile` in order to add the commands to PATH.

```sh
bash InstallationScripts/MSM-install.sh
```
```sh
bash InstallationScripts/Ciftify-install.sh
```
```sh
bash InstallationScripts/Workbench-install.sh
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

The entire pipeline has been bundled into a single Python script with a command line interface. The easiest way to use this pipeline is to either add the cloned repo to PATH or to copy the script itself `MSM_Pipeline.py` and the `Pipeline_Templates` directory into a location that is already part of PATH such as `user/bin.` Once one of the above steps has been completed, ensure that it was done correctly by using the command `MSM_Pipeline -h`. This will bring up the help text, detailing all avaliable commands. Below, I have detailed the various commands avaliable within the pipeline as well as the arguments needed for each one. Note that every argument is a keyword and not positional. `-h` can be used after any command name to see all arguments needed for any command.

### `is_slurm_queue_open`
Checks the slurm queue of the specified user and returns the number of open jobs. Also prints the queue to a .txt file. Note that this assumes a job limit of 500. The slurm queue can still be checked manually 
#### Arguments
* `--slurm_user` The username of the user to check the queue for.

### `get_ciftify_subject_list`
This command is used to retrive a list of all folders of subject data that need to converted using `run_ciftify`.
#### Arguments
* `--dataset` The location of the freesurfer data. This should be the root folder containing all the folders of subjects and time points.
* `--subjects` A space separated list of subject IDs that you want to find the folders names for.
* `--pattern` A regex of the format of the folder name in regards to the location of the subeject ID, using "#" as a placeholder for the ID. e.g. `.*_S_#_.*` this will search for folders that contain `_S_<subject_id>_` with the subject ID being pulled from the list of subjects provided.

### `run_cifitify`
This command is used to run the `ciftify-recon-all` command on the indicated directories and place the output in the indicated folder. This creates one output directory for each input directory in the indicated location.
#### Arguments
* `--dataset` This is the folder where your directories are located. Note: there are plans to make this automatic and remove the need for this argument
* `--directories` A space separated list of directories to run. This can be generated using the `get_ciftify_subject_list` command. Note: there are currently plans to make this automatic and remove the need for this argument
* `--delimiter` The character used to separate fields in the orginal directory name, typically "_"
* `--subject_index` The location of the subject id based on the delimiter, with the first field being 0
* `--time_index` The same as above but for the time point of the scan
* `--output_path` The full path where you want all of the directories created
* `--slurm_account` The slurm account ID used for job allocations
* `--slurm_user` Slurm username for checking queue
* `--slurm_email` The email address you wish for failed job notifications to be sent to
* `--slurm_job_limit` The user's slurm job limit.

### `get_subject_time_points` 
A helper function that lists all time points for a given subject in a given dataset. Useful for troubleshooting.
#### Arguments
* `--dataset` The path to the directory containing subject data.
* `--subject` The subject ID for which timepoints will be retrieved.
* `--alphanumeric_timepoints` Identify whether or not the timepoints are alphanumeric.
* `--time_point_number_start_character` The character where numbers begin in the timepoint; 0 indexed.
* `--starting_time` Provide starting time point if it uses a different naming convention.
    

### `generate_post_processing_image` 
Generates post-processing images based on the directory input.
#### Arguments
* `--subjecct_directory` The path to the directory in which the created MSM output files should be contained.
* `--resolution` Desired resolution of created images. Either CPgrid or ANATgrid.
* `--mode` Identify forward, reverse, or average depending on registration.
* `--output` Location to which output images will be copied. Images will also be placed in the subject directory.
  
### `post_process_all` 
Generates post-processing images for the entirety of the provided dataset.
#### Arguments
* `--dataset` Location of the MSM registrations.
* `--starting_time` The baseline timepoint of data. This value is used to determine whether forward or reverse registration was used.
* `--resolution` Identify resolution of created images. Either CPgrid or ANATgrid.
* `--output` Location to which output images will be copied. Images will also be placed in the subject directory.

### `run_msm` 
Runs forward and reverse registrations of the indicated subject and timepoint.
#### Arguments
* `--dataset` Path to the directory containing all time points for registration.
* `--output` Path for the output of MSM files. A seperate folder for each registration will be created at this path.
* `--subject` The subject ID MSM registration.
* `--younger_timepoint` The younger timepoint for registration.
* `--Older_timepoint` The older timepoint for registration.
* `--mode` Identify forward or reverse registration mode.
* `--levels` Identify the levels of MSM to run. See MSM documentation for more information.
* `--config` Path to the MSM config file to be used. See MSM documentation for more information.
* `--max_anat` Path to MaxANAT reference sphere (typically ico6sphere).
* `--max_cp` Path to MaxCP reference sphere (typically ico5sphere).
* `--slurm_email` Email to which failed job notifications should be sent.
* `--slurm_account` Slurm account ID for submission.
* `--slurm_user` Slurm username for checking queue.
* `--slurm_job_limit` The user's slurm job limit.

### `run_msm_bl_to_all` 
Runs MSM registrations, starting at the baseline timepoint, for each other timepoint availible for a given subject. Multiple subjects can be run if they are all included in the specified folder.
#### Arguments
* `--dataset` The path to the directory containing all data for registration.
* `--alphanumeric_timepoints` Identify whether the timepoints are alphanumeric.
* `--time_point_number_start_character` Identify the character where numbers begin in the timepoint; 0 indexed.
* `--output` The path for output of MSM files. A folder for each registration will be created here.
* `--starting_time` The time point used as a baseline ('bl') for all registrations.
* `--slurm_account` The slurm account ID for submission.
* `--slurm_user` Slurm username used for checking the queue.
* `--slurm_email` Email address to which failed job notifications should be sent.
* `--slurm_job_limit` The user's slurm job limit.
* `--levels` Levels of MSM to run. See MSM documentation for more information.
* `--config` Path to the MSM config file that will be used. See MSM documentation for more information.
* `--max_anat` Path to the MaxANATreference sphere (typically ico6sphere).
* `--max_cp` Path the the MaxCP reference sphere (typically ico5sphere).

### `run_msm_short_time_windows` 
Runs MSM on all subjects in a folder using sequential timepoints.
#### Arguments
* `--dataset` The path to the directory containing all data for registration.
* `--alphanumeric_timepoints` Identify whether the timepoints are alphanumeric.
* `--time_point_number_start_character` The character where numbers begin in the timepoint; 0 indexed.
* `--output` Path for the MSM output files. A folder for each registration will be created here.
* `--slurm_account` The slurm account ID for submission.
* `--slurm_user` The slurm username for checking the queue.
* `--slurm email` The email to which failed job notifications will be sent.
* `--slurm_job_limit` The user's slurm job limit.
* `--levels` Levels of MSM that will be run. See MSM documentation for more information.
* `--config` Path to the MSM config file that will be used. See MSM documentation for more information.
* `--max_anat` Path to the MaxANAT reference sphere (typically ico6sphere).
* `--max_cp` Path to the MaxCP reference sphere (typically ico5sphere).
* `--starting time` The starting time point. This is only necessary if baseline registrations should be skipped.

### `generate_avg_maps` 
Generates an average map for the specified subject and time points.
#### Arguments
* `--ciftify_dataset` Path to the folder containing ciftify outputs.
* `--msm_dataset` Path to MSM registrations.
* `-- subject` The subject ID that will be used to generate average maps.
* `--younger_timepoint` The younger timepoint of the registration.
* `--older_timepoint` The older timepoint of the registration.
* `--max_cp` Path to the MaxCP reference sphere (typically ico5sphere)
* `--max_anat` Path to the MaxANAT reference sphere (typically ico6sphere).

### `generate_avg_maps_all` 
Generates average maps for all registrations in the specified directory.
#### Arguments
* `--ciftify_dataset` Path to the folder containing ciftify outputs.
* `--msm_dataset` Path to MSM registration.
* `--max_cp` Path to the MaxCP reference sphere (typically ico5sphere).
* `--max_anat` Path to the MaxANAT reference sphere (typically cio6sphere)
* `--starting_time` The baseline time of registrations. This is used to determine which average maps are needed.

**DEPRECATED**

All scripts provided have a section where various variables can be changed to suit the needs of the user. Be sure to check this section for accuracy before running any scripts. These will mostly be able to guide you through the usage of each one. Further instructions are detailed below.

Once you have installed the verious tools as outlined in the previous step, you are now ready to begin running analysis on the data. To get started you will need to have access to data from at least one subject at two different time points. This pipeline assumes you are starting from raw Freesurfer output. The first step is to use `Ciftify_Subject_List.sh` to generate a txt file with the folder names of the subjects which need to be converted from Freesurfer to HCP format using `ciftify_recon_all`. Note that this script is set up to look for one of two possible naming conventions `*_S_<SUBJECT#>_*` or `<SUBJECT#>_*` as these two naming conventions are the ones used by ADNI and IADRC respectively. If your data is in a different format the script can be easily updated to handle that. Furthermore, if the dataset you wish to test is small enough, you can simply create a txt document manually where the folder name for each folder, without the path, is listed on a seperate line.

After obtaining the txt file of subjects you are now ready to run the `ciftify_recon_all` command on the data to begin the conversion process. In order to simplify this process the script `RunCiftify.sh` should be used. A few things to note: as with all scripts, be sure to check the variable definitions at the top of the script before running. At the very least you will need to update the `SUBJECT_TXT` variable to point to the txt file you just created. Secondly, you will need to provide the script with information about your naming convention. Specifically you will need to provide a `DELIMITER`. This is whatever character is used to seperate fields in the directory name, "\_" is a typical one. You'll also need to provide the `SUBJECT_POSISTION` and `TIME_POINT_POSISTION`. These are simply where in the folder name your subject and time point can be found in regards to the delimiter selector. For example, if your naming convention is `SUBJECT_<SUBJECt#>_<SCAN#>` your positions would be 2 and 3 with a delimiter of "\_". Finally, `ciftify_recon_all` is a very intensive process that takes a very long time to run. As such the script assumes that the work is being done on a high powered cluster computing system through the use of Slurm. If this is not the case the script will again need to be edited to use a different workload manager or to be ran locally. It is strongly advised to not run this script locally as even a single run of the `ciftify_recon_all` command can take upwards of two hours and, since the pipeline requires at least two timepoints, this would subsequently take over 4 hours to complete the full script.

The third step in the pipeline is to run MSM on the dataset. This is accomplished through the use of the `RunMSM.sh` script. As usual ensure that all variables are correct for your system before proceeding. The only special thing to note is that the first timepoint for each subject must be assign using the `STARTING_TIME` variable. This is what ever your naming convention designates as the earliest time point for each subject. It should be unique (only one per subject) and every subject being ran should have this time point. All subjects are assumed to follow the naming convention `Subject_<subject#>_<timepoint>` as these folders are generated in the previous step. As with Ciftify, it is not recommended to run this on a local machine as even a single registration can take upwards of 8 hours, with a single run of the script requiring two regestrations (one forward and one reverse).

Following these steps will get you an output of folders with the maps and surfaces ready to view using Workbench. Other scripts, such as `PostProcessing.sh` and `InvertSurfdist.sh` serve as examples of postprocessing that can be done such as generating images of the registrations through Workbench, or inverting the reverse registration map so that it is the same as the relevant forward registration, useful for eliminating noise. Finally, all extra files can be found in the 'NeededFiles' directory.

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Project Link: [https://github.com/KEGarciaLab/aMSM_AD](https://github.com/KEGarciaLab/aMSM_AD)

Project Lead: [Dr. Kara Garcia](mailto:karagarc@?subject=[GitHub]aMSM_AD)

Script Manager: [Sammy Rigdon IV](mailto:srigdon5@?subject=[GitHub]aMSM_AD)

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* <a href="https://github.com/othneildrew/Best-README-Template"> Read me tepmplate by othneildrew</a>

* This Project is based on scripts and processes developed in the following publication: <a href="https://onlinelibrary.wiley.com/doi/full/10.1002/hbm.25455"> Iannopollo, E., Garcia, K., & Alzheimer's Disease Neuroimaging Initiative. (2021). Enhanced detection of cortical atrophy in Alzheimer's disease using structural MRI with anatomically constrained longitudinal registration. Human Brain Mapping, 42(11), 3576-3592.</a>

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/KEGarciaLab/aMSM_AD.svg?style=for-the-badge
[contributors-url]: https://github.com/KEGarciaLab/aMSM_AD/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/KEGarciaLab/aMSM_AD.svg?style=for-the-badge
[forks-url]: https://github.com/KEGarciaLab/aMSM_AD/network/members
[stars-shield]: https://img.shields.io/github/stars/KEGarciaLab/aMSM_AD.svg?style=for-the-badge
[stars-url]: https://github.com/KEGarciaLab/aMSM_AD/stargazers
[issues-shield]: https://img.shields.io/github/issues/KEGarciaLab/aMSM_AD.svg?style=for-the-badge
[issues-url]: https://github.com/KEGarciaLab/aMSM_AD/issues
[license-shield]: https://img.shields.io/github/license/KEGarciaLab/aMSM_AD.svg?style=for-the-badge
[license-url]: https://github.com/KEGarciaLab/aMSM_AD/blob/master/LICENSE.txt
[product-screenshot]: images/screenshot.png
[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com 
