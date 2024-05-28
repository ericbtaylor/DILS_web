# DILS

# 1 - Dependencies

[singularity](https://sylabs.io/docs/) (tested with 3.1.1)   
	
# 2 - Installation

More details are provided in the **manual.pdf** file.  

## clone git repository  

This repository is a fork of https://github.com/popgenomics/DILS_web . It provides
a few improvements and bugfixes over the original repository:

- All dependencies are pulled into a [Dockerfile](./Dockerfile), with very specific package versions.
- The Dockerfile can produce a docker image that can be run in singularity.
- I've cleaned up several scripts, which had a few hardcoded parameters which didn't work in all environments.

```
git clone https://github.com/init-js/DILS_web.git

# or

git clone git@github.com:init-js/DILS_web.git
```

Then enter the repository directory:

```
cd DILS_web
```


## Build the singularity image

You now need to create a singularity image file with all the binaries
and scripts from DILS.

Why?

Singularity is a container model which allows packaging a set of
dependencies and programs into a single unit. It is generally the
preferred mechanism to run arbitrary software in a multi-user
environment (such as university lab computers) because of its security
properties.

Rather than installing a bunch of software on your machine, with very
specific version requirements which could clash with the versions
already installed on the host, Singularity allows you to install
specific versions of the software into an isolated software "sandbox"
-- also called a "singularity image", and then run this image as if it
was a single binary program, i.e. with arguments. You can think of a
singularity image as a closed box which can do some arbitrary
processing or conversions, or even run a small server that you can
connect to.


> If your goal is simply to run DILS, then skip this subsection. Go
> directly to section "Download the singularity image".

### Building the singularity image from scratch

The file `DILS.def` is a template recipe to build the singularity
image. It issues a list of commands to setup the environment, install
python, and R, packages, and configure a program entry point (the
webserver for DILS). Unfortunately, the original authors didn't
specify the particular versions of software that should be pulled as
dependencies, so running this today will actually install the latest
versions of the packages as of today -- which are not the same that were
originally intended by the authors. You will in fact run into all sorts
of version conflicts because the latest versions of all packages are
no longer compatible with one another.

JS Edit 2023/2024: I've gone back to the original paper, and read the
manual, and found/inferred a working combination of software versions
that seems to work Okay. I've translated the `DILS.def` singularity
template into a Dockerfile, and specified a combination of packages
that seems to work okay.

Deprecated: The original way to build the singularity image was to use
this `.def` template.  If you had sufficient administrative
credentials on your system, you would run the following command. I'm
only mentioning it for "legacy" purposes, because this no longer works
due to the version conflicts I mentioned earlier:

```
sudo singularity build DILS.sif DILS.def
```

You would typically require admin/root privileges to build new
containers (because the process involves privileged operations, like
mounting loop devices and creating files owned by root), whereas any
regular user can run singularity.

JS: I've gone through this hassle once (on a system for which I had
administrative privileges), and published the image to this dockerhub
repository. It is available to the public, and anyone can download it

The next step will show you how to convert this docker image to a
singularity image that you can run in your lab environment.

https://hub.docker.com/repository/docker/initjs/dils

If you were to make further modifications to the Dockerfile (e.g. if you
wanted to add more software to the DILS image), you'd have to publish
a new version of the image. If you wanted to do this, you would apply
your changes to the dockerfile, then commit the changes to the repository
in git, and rebuild the docker image like so:

```
# assuming your dockerhub username is `myusername`
docker build -t myusername/my-dils .
```

This should recreate a docker image, with all the software at the required
versions. It will take a few minutes -- the conda environment stuff is
pretty slow.

## Download the singularity image

I've pre-packaged the DILS distribution into a public docker image
on dockerhub. Version 1 of the docker image corresponds to
git commit 2bef4a39b3719e68a8c6d806c9930c0893578edd. If you need
a custom image, you will need to follow the instructions in the
previous subsection.

You will need to store the singularity image in the file `DILS.sif` 
inside the `DILS_web` directory (i.e. the repository's root directory).

As a regular user, you should be able to pull the publicly available
docker image (`initjs/dils:1`) into a local dils singularity
image. This will create a large file called `DILS.sif`
(sif == singularity image file).

```
cd DILS_web && \
singularity pull DILS.sif docker://initjs/dils:1
```

> Note for zoology cluster: Not all machines have singularity installed.
> mank03 and mank04, at the very least, should have it.

The command above will take a few minutes (be patient), and you should
end up with a file called DILS.sif in the local directory. This
`DILS.sif` is a 1-file package that contains all the scripts and
programs needed by dils to do its thing.

(Both `singularity build ...`, and `singularity pull ...` create a
singularity image file, but unlike `build`, the `pull` command does
not require administrative privileges, because `pull` merely converts an
image that is already built elsewhere -- that's the main difference.)

## Execution in the UBC zoology cluster

> Note: You will need to run this program on one of the computers that has
> `singularity` installed. The scripts require running `DILS.sif` downloaded
> earlier.

### 1. Create a directory that will host your dils data files and configuration

```
XDIR=~/my-experiment # or anywhere you like
REPO="/path/to/DILS_web/" # absolute path to DILS_web repo

mkdir -p "$XDIR"
cd "$XDIR
```

> The "$REPO" directory is expected to contain file DILS.sif

### 2. Configure your yaml configuration file, as specified in the DILS manual.

Example (file trial.yaml):

```
mail_address: geraldes@zoology.ubc.ca
infile: /app/DILS_pop_samples_fa
region: noncoding
nspecies: 2
nameA: AC
nameB: NDV
nameOutgroup: BRT
lightMode: TRUE
useSFS: 1
timeStamp: trial 
population_growth: constant
modeBarrier: bimodal
max_N_tolerated: 0.2
Lmin: 40
nMin: 6
mu: 0.00000002763
rho_over_theta: 0.5
N_min: 0
N_max: 500000
Tsplit_min: 0
Tsplit_max: 1750000
M_min: 1
M_max: 40
```

> Save the above file into `$XDIR/trial.yaml`

Pay particular attention to the path prefix used by the `infile`
parameter. Note that it starts with `/app/`. This is a special
"virtual" path which only exists _inside_ the singularity container
when it runs. Whatever is inside the directory `$XDIR` will be
"mounted" at path `/app/` inside the container. So just think of
`/app/` as something that dils will understand to be `$XDIR`.

The file `DILS_pop_samples_fa` is a fasta file that we need for our
experiment. Copy it in the same folder as `$XDIR`, with our yaml file.

```
# the filename inside the yaml should match the name in the destination.
# but does not need to be exactly this value.
cp path/to/my/fasta "$XDIR/DILS_pop_samples_fa"
```

### 3. Start the experiment

Inside "$XDIR" run the following:

```
# make a symlink to the dils script inside the current dir
ln -s "$REPO"/run_dils_2pop.sh
```

Now we can start the script:

```
# this will run for a few hours (2-3). so consider running inside tmux/screen.
./run_dils_2pop.sh trial.yaml
```

That script is a wrapper around our singularity image and ends up running something like this:

```
singularity run "${BIND_ARGS[@]}" "$SIF" 2pop "$YAML" 2>&1 | tee run_trial.log
```

Where `$YAML` is our yaml file above, and 2pop is the mode of operation that we want dils to use.
(this mode is described in the manual). The only other supported mode is '1pop'.

> A note on "entrypoints": When the singularity image (DILS.sif) starts running, by
> default it runs our container using a special program designated as the "entrypoint". This entrypoint
> is yet another wrapper, located in `DILS_web/DILS/bin/entrypoint.sh`. All the entrypoint does is
> chain the given arguments into snakemake command line parameters.
>
> Snakemake is the system used by DILS to specify the steps of the "bioinformatics" pipeline applied
> to the fasta.

When you run `run_dils_2pop.sh`, you will see a series of jobs execute, e.g.:

```
...
Finished job 6.
73 of 184 steps (40%) done

[Mon May 27 23:00:12 2024]
rule simulation_best_model:
    input: trial/modelComp/best_model.txt, trial/nLoci.txt, trial/bpfile
    output: trial/best_model/best_model_6/priorfile.txt, trial/best_model/best_model_6/ABCstat.txt
    jobid: 123
    wildcards: timeStamp=trial, i=6


                best_model=$(cat trial/modelComp/best_model.txt)
                pypy /tools/bin/submit_simulations_2pop.py 1 1000 6 ${best_model} AC NDV best_model best_model /tmp/snakemake.config.nDGGL.yaml trial bimodal /tools/bin
                sleep 30

cp /app/trial/bpfile /app/trial/best_model/best_model_6/; cd /app/trial/best_model/best_model_6/; pypy /tools/bin/priorgen_2pop.py IM_1M_2N 1000 /tmp/snakemake.config.nDGGL.yaml | /tools/bin/msnsam tbs 1000000 -t tbs -r tbs tbs -I 2 tbs tbs 0 -n 1 tbs -n 2 tbs -m 1 2 tbs -m 2 1 tbs -ej tbs 2 1 -eN tbs tbs | pypy /tools/bin/mscalc_2pop_SFS.py 1
[Mon May 27 23:01:20 2024]
Finished job 123.
...
```

What snakemake is doing, is planning ahead the full set of commands
that need to happen to produce the final output of DILS, and running
as many commands as it can in parallel.

You can see for each command that runs the input files (`input: ...`),
and the output files just for that step of the pipeline (`output: ...`).
The folder `trial` matches the basename of your `.yaml` file.

### 4. Wait for snakemake to complete

Eventually snakemake will finish all the jobs. (On mank03/04 it takes a few hours).

A copy of all the logs is kept in `$XDIR/<yaml>.log`. You should also
have a folder called `trial` (based on what your yaml prefix is),
containing all the temporary and final outputs of ALL the snakemake
jobs.

If snakemake crashes for one reason or another, you will probably have to
inspect the script that caused the issue. You should be able to re-run
the `run_dils_2pop.sh` script, and snakemake is typically good about
redoing only the steps that are remaining (i.e. it will resume).

Snakemake determines whether a step in the pipeline needs to be
executed based on whether the outputs of a candidate command already
exist. So if partial outputs are there (e.g. half the pipeline is completed),
it should skip those steps on the following run. 

Note that in some cases, output files are prematurely created before
they are filled with valid content, (those are bugs in the scripts),
so you do have to keep an eye out for those types of issues. If you're seeing
strange behaviours that you can't quite explain, it can be a good idea
to delete the files you think are corrupt, and let snakemake recompute them.


## run the shiny app (may need root permissions):

> JS Note: I've not had great success with the web interface to be
> honest. What I've personally done is look at the code that the web
> scripts actuate, and exported that into an equivalent command line.
>
> You can most likely ignore the following section -- the one explaining
> how to run the web interface.

```
sudo singularity exec --bind DILS/:/mnt DILS.sif host=[ip adress of your server] port=[port number where shiny is reachable] nCPU=[maximum number of CPUs to use simultaneously]
```

e.g. with a big machine with 100 CPUs:  

```  
sudo singularity exec --bind DILS/:/mnt DILS.sif webinterface/app.R host=127.0.0.9 port=8912 nCPU=100
```  

Please keep in mind that the max number of CPUs is the maximum number of CPUs DILS will use at certain times, but that DILS will not use 100% of the indicated number of CPUs throughout its whole run. This maximum usage will be punctual.  
  
shiny app is now available in your web browser at http://[ip adress of your server]:[port number],  
eg:  
```
http://127.0.0.9:8912/
```
But chose the IP adress and port number you want 
  
# 4 - Example  
## Execute DILS in your web browser
In your terminal, from the DILS_web directory:  
```  
singularity exec --bind DILS/:/mnt DILS.sif webinterface/app.R host=127.0.0.9 port=8912 nCPU=100
```  
May require `sudo` to be run
  
Then in your web brower:  
```
http://127.0.0.9:8912/
```

## Running ABC from a fasta file  
All example files are in the **example** sub_directory.  

### 1. Unarchive the example file  
DILS **only** works with **fasta files**. The example file is a tar.xz file only to store it on GitHub, but not to be read in DILS. In this case here, you must first decompress the archive like this:  
```
tar -Jxvf mytilus.tar.xz
```
Will generates the input file: 
```
mytilus.fas
```

###  2. Run a demographic ABC analysis  
Upload the **fasta** file by clicking on:  
1. ABC  
2. Upload data  
3. Browse (Input file upload)  
  
Then you can set up the analysis and execute it.  

## 3. Exploring the results
Upload the archive produced by DILS in a **tar.gz format** (doesn't need to be extracted) by clicking on:  
1. Results visualization  
2. Upload results  
3. Browse (Results to upload)  

Then you can explore the observed data and the results of the inferences.  

# 5 - Help and support  
For problems of installation, use or interpretation, do not hesitate to post a message on the following group:  
https://groups.google.com/forum/#!forum/dils---demographic-inferences-with-linked-selection 

