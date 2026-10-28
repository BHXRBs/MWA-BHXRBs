
# MWA-BHXRBs 🔭

**A pipeline for reducing Murchison Widefield Array (MWA) observations of black hole X-ray binaries (BHXRBs).**

This repository contains scripts for downloading, calibrating, and imaging MWA observations on the Pawsey Supercomputing Research Centre's Setonix cluster. The pipeline uses containerised radio astronomy software to help streamline the data reduction workflow.

## 📑 Table of Contents

- [Overview](#-overview)
- [Prerequisites](#-prerequisites)
- [1. Installation](#1-installation)
- [2. Configuration](#2-configuration)
- [3. Download and prepare the observations](#3-download-and-prepare-the-observations)
- [4. Run the pipeline](#4-run-the-pipeline)
- [5. Example: 150 MHz observations](#5-example-150-mhz-observations)
- [Output directories](#-output-directories)
- [Known limitations and future improvements](#-known-limitations-and-future-improvements)

---

## 🔬 Overview

The pipeline currently supports the following steps:

| Stage | Description |
|---|---|
| **Data retrieval** | Moves converted MWA observations from ASVO to your working directory on Pawsey. |
| **Calibration** | Flags RFI, performs initial calibration and self-calibration, and generates calibration diagnostic plots. |
| **Imaging** | Applies calibration solutions and produces primary-beam-corrected images using WSClean. |


## ✅ Prerequisites

Before getting started, you will need:

- Access to the **Pawsey Setonix** cluster and the relevant project allocation.
- An account with access to the required MWA observations through the **MWA ASVO portal**.

The scripts are configured for the Pawsey environment and use the `mwasci` account by default. You may need to adjust the configuration to suit your allocation.

---

## 1. Installation

### Step 1: Clone the repository

Log in to Pawsey and clone the repository into your preferred working directory. The following example assumes that you are using `/scratch/mwasci/<username>/`.

```bash
cd /scratch/mwasci/${USER}
git clone https://github.com/BHXRBs/MWA-BHXRBs.git
cd MWA-BHXRBs
```

### Step 2: Download the containers and beam model

Navigate to the `containers` directory and run the download script.

```bash
cd containers
./downloadFiles.sh
cd ..
```

This downloads the containers required by the pipeline:

- `mwa-reduce`
- `aoflagger`
- `hyperdrive`
- `wsclean`

It also downloads the MWA full embedded-element beam model used for imaging.


---

## 2. Configuration

Several configuration files and scripts contain paths and settings specific to my Pawsey account. **You will need to update these before running the pipeline.**

In the examples below, replace `<username>` with your Pawsey username.

### Step 1: Update `aliases`

Open the `aliases` file in the repository root.

```bash
nano aliases
```

Replace `/scratch/mwasci/sprabu/MWA-BHXRBs/containers/` with the corresponding path to your containers.

For example, if your repository is located at `/scratch/mwasci/<username>/MWA-BHXRBs`, update the container paths accordingly.

### Step 2: Update `config.txt`

Open `config.txt` and update the `MYBASE` variable.

```bash
nano config.txt
```

For example:

```bash
MYBASE="/scratch/mwasci/<username>/MWA-BHXRBs"
MYCLUSTER="setonix"
MYACCOUNT="mwasci"
```

Adjust `MYACCOUNT` if you are using a different Pawsey allocation.

### Step 3: Update the path to `aliases`

The Slurm scripts also contain absolute paths to the `aliases` file.

Replace `/scratch/mwasci/sprabu/MWA-BHXRBs/aliases` with your own path in:

- `bin/calibrate.sh`
- `bin/image.sh`
- `bin/obsget.sh`

For example:

```bash
source /scratch/mwasci/<username>/MWA-BHXRBs/aliases
```

### Step 4: Configure job-failure notifications

The pipeline is configured to email a notification when a job fails or reaches its time limit. By default, the email address is mine, so **please update this to your own email address** to avoid sending me notifications whenever your jobs fail!

In each of the following files:

- `bin/calibrate.sh`
- `bin/image.sh`
- `bin/obsget.sh`

Change the `#SBATCH --mail-user` directive to your preferred email address.

```bash
#SBATCH --mail-type FAIL,TIME_LIMIT
#SBATCH --mail-user your.email@example.com
```

---

## 3. Download and prepare the observations

### Step 1: Submit ASVO conversion jobs

Using the MWA ASVO portal, submit a conversion job for each observation you want to process.

Recommended settings:

| Parameter | Setting |
|---|---|
| Time averaging | 2 seconds |
| Frequency resolution | 40 kHz |
| Delivery location | Scratch |
| Delivery format | Tar Archive |

Once the conversion jobs have completed, navigate to the **My Jobs** section of ASVO and record the Slurm job ID associated with each conversion job.

You will need these job IDs to retrieve the converted data onto Setonix.

ASVO conversion-job submission is currently a manual step. TODO: Automating this process using`giant-squid`.
---

## 4. Run the pipeline

The pipeline uses three main scripts to retrieve, calibrate, and image the observations:

| Script | Purpose |
|---|---|
| `bin/obs_obsget.sh` | Retrieves a converted observation from ASVO to your working directory. |
| `bin/obs_calibrate.sh` | Flags and calibrates an observation, including self-calibration. |
| `bin/obs_image.sh` | Applies calibration solutions and creates primary-beam-corrected images. |

The following worked example demonstrates how to reduce a set of 150 MHz observations.

---

## 5. Example: 150 MHz observations

For this example, we use MWA observations from 28 August 2016.

The dataset consists of one calibrator observation of Hercules A (HerA) and five target observations.

| Observation type | Observation ID |
|---|---|
| Calibrator (HerA) | `1471951792` |
| Target 1 | `1471951912` |
| Target 2 | `1471952032` |
| Target 3 | `1471952152` |
| Target 4 | `1471952272` |
| Target 5 | `1471952392` |

The five target observations are imaged together to produce a deeper, stacked image.

### Step 1: Retrieve the observations

Navigate to the repository directory:

```bash
cd /scratch/mwasci/${USER}/MWA-BHXRBs
```

Run the retrieval script for each observation, replacing each placeholder with the corresponding ASVO Slurm job ID.

```bash
./bin/obs_obsget.sh -o 1471951792 -s ${slurmID1}
./bin/obs_obsget.sh -o 1471951912 -s ${slurmID2}
./bin/obs_obsget.sh -o 1471952032 -s ${slurmID3}
./bin/obs_obsget.sh -o 1471952152 -s ${slurmID4}
./bin/obs_obsget.sh -o 1471952272 -s ${slurmID5}
./bin/obs_obsget.sh -o 1471952392 -s ${slurmID6}
```

Each command submits a Slurm job to retrieve and unpack the corresponding observation.

The observations will be placed under the repository's `processing/` directory.

### Step 2: Calibrate the observation

Once the calibrator observation has been retrieved, run:

```bash
./bin/obs_calibrate.sh -o 1471951792 -m HerA
```

This step performs the calibration workflow, including:

1. RFI flagging using AOFLAGGER.
2. Initial calibration using the calibrator model.
3. Application of calibration solutions.
4. Initial imaging.
5. Self-calibration.
6. Final imaging and calibration diagnostics.

The script also generates plots of the calibration solution amplitudes and phases for each antenna.

Check the job output and calibration plots before proceeding to imaging the target observations.

### Step 3: Create a stacked target image

The imaging script accepts multiple target observation IDs using repeated `-o` arguments.

For example, to image all five target observations together:

```bash
./bin/obs_image.sh \
    -n demoImage \
    -c 1471951792 \
    -o 1471951912 \
    -o 1471952032 \
    -o 1471952152 \
    -o 1471952272 \
    -o 1471952392
```

Here:

- `-n demoImage` specifies the output image name.
- `-c 1471951792` identifies the calibrator observation containing the calibration solutions.
- Each `-o` specifies a target observation to include in the image.

The script applies the calibrator solutions to the target observations and runs WSClean to create images using both Briggs and natural weighting. Primary-beam correction is enabled.

The resulting images are saved in the `images/` directory using the name specified by `-n`.

**Examples:**

| Input | Behaviour |
|---|---|
| `-o 123` | Image one observation. |
| `-o 123 -o 345` | Image two observations together. |
| `-o 123 -o 345 -o 678` | Image three observations together. |

---

## 📂 Output directories

After running the pipeline, the main directories are:

| Directory | Contents |
|---|---|
| `containers/` | Downloaded software containers and the MWA beam model. |
| `processing/` | Retrieved measurement sets, calibration solutions, and intermediate products. |
| `images/` | Final images generated by WSClean. |
| `queue/` | Generated Slurm scripts and job logs. |
| `models/` | Calibrator sky models used during calibration. |

---

## 🚧 Known limitations and future improvements

The following improvements are currently on the to-do list:

- [ ] **Source amplitude corrections:** Integrate `flux_warp.py` for possible source-amplitude corrections. This has not yet been incorporated because it is unlikely to be required for MAXI J1750, which is located at the phase centre.
- [ ] **Target-field self-calibration:** Add optional self-calibration using the target field. This should be straightforward to implement, but care will be needed with the cleaning parameters for complex fields, particularly those towards the Galactic Centre, to avoid introducing imaging artefacts.
- [ ] **Background modelling and subtraction:** If MAXI J1750 becomes difficult to detect in observations where it is expected to be faint, investigate modelling and subtracting the background to reduce the noise floor.

---

## 🎯 Happy hunting, XRBs!

If you encounter issues or have suggestions for improving the pipeline, please feel free to get in touch or open an issue in the repository.
