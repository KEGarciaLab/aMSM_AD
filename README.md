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

All scripts used for installation of the various tools can be found in Installation folder of the repo. They should be ran in the order listed below to avoid errors. It is also reccomended that you either reboot your system (or reconnect through an ssh) after each installation to ensure it was completed properly. Finally, the MSM install was made assuming this would be ran on one of the IU supercomputing clusters. If you are outside of IU or are not using one of these systems you will need to manually install MSM and ensure that it is installed in the folder `MSM_HOCR-master` located in your Home directory. Failure to follow these steps will cause the ciftify install to fail.

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

All scripts provided have a section where various variables can be changed to suit the needs of the user. Be sure to check this section for accuracy before running any scripts. These will mostly be able to guide you through the usage of each one. Further instructions are detailed below.

Once you have installed the verious tools as outline in the previous step, you are now ready to begin running analysis on the data. To get started you will need to have access to data from at least one subject at two different time points. This pipeline assumes you are starting from raw Freesurfer output. The first step is to use `Ciftify_Subject_List.sh` to generate a txt file with the folder names of the subjects which need to be converted from Freesurfer to HCP format using `ciftify_recon_all`. Note that this script is set up to look for one of two possible naming conventions `*_S_<SUBJECT#>_*` or `<SUBJECT#>_*` as these two naming conventions are the ones used by ADNI and IADRC respectively. If your data is in a differenet format the script can be easily updated to handle that. Furthermore, if the dataset you wish to test is small enough, you can simply create a txt documnet manually where the folder name for each folder, without the path, is listed on a seperate line.

After obtaining the txt file of subjects you are now ready to run the `ciftify_recon_all` command on the data to begin the conversion process. In order to simplify this process the script `RunCiftify.sh` should be used. A few things to note: as with all scripts, be sure to check the variable definitions at the top of the script before running. At the very least you will need to update the `SUBJECT_TXT` variable to point to the txt file you just created. Secondly, the script assumes one of the two naming conventions mentioned in the previous step. If your dataset uses a different naming convention then you will need to edit the script to accomodate this. Finally, `ciftify_recon_all` is a very intemsive process that takes a very long time to run. As such the script assumes that the work is being done on a high powered cluster computing system through the use of Slurm. If this is not the case the script will again need to be edited to use a different workload manager or to be ran locally. It is strongly advised to not run this script locally as even a single run of the `ciftify_recon_all` command can take upwards of two hours and, since the pipeline requires at least two timepoints, this would subsequently take over 4 hours to complete the full script.

The third step in the pipeline is to run MSM on the dataset. This is accomplished through the use of the `RunMSM.sh` script. As usual ensure that all variables are corect for your system before proceeding. The only special thing to note is that the first timepoint for each subject is assumed to be `BL` and all subjects follow the naming convention `Subject_<subject#>_<timepoint>`. As these folders are generated in the previous step the naming convention will be correct but may require manual correction of some time points, including the designation of a `BL` timepoint if one doesn't already exist. As with Ciftify it is not reccomended to run this on a local machine as even a single registration can tak upwards of 8 hours, with a single run of the script requiring two regestrations (one forward and one reverse).

Following these steps will get you an output of folders with the maps and surfaces ready to view using Workbench. Other scripts, such as `ADNIPostProcessing.sh` and `InvertSurfdist.sh` serve as examples of postprocessing that can be done such as generating images of the registrations through Workbench, or inverting the reverse registration map so that it is the same as the relevant forward registration.

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
