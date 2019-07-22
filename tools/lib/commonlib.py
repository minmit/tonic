import re, os, subprocess, shlex
import dbglib as dbg

def launchSlurmJob(job_name, cmd, slurm_dep_l, flog_path):
    slurm_file = job_name + ".slurm"
    fp = open(slurm_file, "w")
    fp.write("#!/bin/sh\n")
    fp.write("#SBATCH -N 1\n")
    fp.write("#SBATCH -c 8\n")
    fp.write("#SBATCH --mem=65536\n")
    fp.write("#SBATCH -t 24:00:00\n")
    fp.write("#SBATCH -J %s\n\n" % job_name)
    fp.write("%s > %s" % (cmd, flog_path))
    fp.close()

    os.chmod(slurm_file, stat.S_IRWXU | stat.S_IRWXG | stat.S_IRWXO)

    retry_limit = 128

    if len(slurm_dep_l) > 0:
        opt_dep = "--dependency=afterok:" + ':'.join([str(job_id) for job_id in slurm_dep_l])
    else:
        opt_dep = ''

    slurm_cmd = "sbatch %s %s" % (opt_dep, slurm_file)
    dbg.print_info("Slurm command: %s" % slurm_cmd)
    proc = subprocess.Popen(shlex.split(slurm_cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = proc.communicate()
    retry_cnt = 1
    while proc.returncode != 0:
        if retry_cnt > retry_limit:
            dbg.print_error("Failed to submit command %s through slurm" % cmd)
            return None
        else:
            dbg.print_info("Slurm submission failed. Retrying in 30 seconds...")
            time.sleep(30)
            dbg.print_info("Submitting slurm job")
            proc = subprocess.Popen(shlex.split(slurm_cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, err = proc.communicate()

    # Get job ID
    match = re.match("Submitted batch job (\d+)\n", out)
    if match != None:
        job_id = int(match.group(1))
        dbg.print_info("Submitted batch job %d" % job_id)
        return job_id
    else:
        dbg.print_error("Can't find submitted job id!")
        return None

# Nonblocking
# Returns process ID
def launchJob(job_name, cmd, use_slurm, slurm_dep_l, flog):
    if use_slurm:
        pid = launchSlurmJob(job_name, cmd, slurm_dep_l, flog)
    else:
        pid = subprocess.Popen(shlex.split(cmd), stdout=flog, stderr=flog)

    return pid

def strInFile(fpath, str_l):
    try:
        f = open(fpath, 'r')
        fdata = f.read()
        f.close()
    except IOError:
        dbg.print_error("Can't open file: %s" % fpath)
        return False

    # File was opened and read
    for s in str_l:
        m = re.search(s, fdata)
        if m == None:
            return False

    return True