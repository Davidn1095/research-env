# Research Environment Container

R 4.3.3 + Bioconductor 3.18 + Python 3.10 container for single-cell and autoimmune atlas analysis.

## Contents

- **Base**: Ubuntu 22.04 + R 4.3.3 + Bioconductor 3.18 + Python 3.10.12
- **495 R packages**: Seurat 5.4, LIANA, CellChat, hdWGCNA, DESeq2, xgboost, WGCNA, ComplexHeatmap, and more
- **12 Python packages**: numpy, pandas, scipy, scikit-learn (for R/reticulate interop)
- **System libraries**: libhdf5, libgsl, libgdal, libcairo, jags, libboost, and more

## How to build

### One-time setup

1. Create a GitHub repo at `https://github.com/Davidn1095/research-env`
2. Push this directory to it:
   ```bash
   cd ~/container-build
   git init
   git add .
   git commit -m "Initial container build setup"
   git remote add origin git@github.com:Davidn1095/research-env.git
   git push -u origin main
   ```
3. Go to **Settings > Actions > General** and set **Workflow permissions** to **Read and write permissions**
4. Go to **Settings > Actions > General** and check **Allow GitHub Actions to create and approve pull requests** (optional)

### Trigger a build

1. Go to the **Actions** tab in the repository
2. Select **Build and Push Container** from the left sidebar
3. Click **Run workflow**
4. Enter the tag (default: `2026.03`)
5. Click the green **Run workflow** button

The workflow will:
- Build the Docker image (~1-3 hours)
- Run smoke tests (Seurat, LIANA, DESeq2, package counts)
- Push to `ghcr.io/davidn1095/research-env:2026.03` only if all tests pass

## How to pull on Picasso HPC

```bash
# On the login node (compute nodes have no internet)
module load singularity/3.7.2
singularity pull docker://ghcr.io/davidn1095/research-env:2026.03
```

This creates `research-env_2026.03.sif` in the current directory.

Or use the provided script:
```bash
bash ~/container-build/picasso_pull_and_test.sh
```

## How to use on Picasso

```bash
# Run an R script
singularity exec \
    --bind /mnt:/mnt,/mnt2:/mnt2,/localscratch:/localscratch \
    research-env_2026.03.sif \
    Rscript --vanilla my_script.R

# Run a Python script
singularity exec \
    --bind /mnt:/mnt,/mnt2:/mnt2 \
    research-env_2026.03.sif \
    python3 my_script.py

# Interactive R session
singularity exec \
    --bind /mnt:/mnt,/mnt2:/mnt2,/localscratch:/localscratch \
    research-env_2026.03.sif \
    R
```

## Overflow folder for future packages

The container sets `R_LIBS_USER` and `PYTHONUSERBASE` to bind-mountable paths.
To install additional packages without rebuilding:

```bash
# Create the overflow directories (once)
mkdir -p /mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/R_overflow
mkdir -p /mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/py_overflow

# Install an R package into the overflow folder
singularity exec --bind /mnt:/mnt,/mnt2:/mnt2 \
    research-env_2026.03.sif \
    Rscript -e 'install.packages("newpkg")'
# It will automatically install to R_overflow/ since R_LIBS_USER is set

# Install a Python package into the overflow folder
singularity exec --bind /mnt:/mnt,/mnt2:/mnt2 \
    research-env_2026.03.sif \
    pip3 install --user newpkg
# It will install to py_overflow/ since PYTHONUSERBASE is set
```

When the overflow folder grows too large, incorporate those packages into the
Dockerfile and trigger a new build.

## Making the image public (optional)

By default, GHCR packages inherit the repo visibility. If the repo is private,
you need to make the package public for `singularity pull` to work without
authentication:

1. Go to `https://github.com/users/Davidn1095/packages/container/research-env/settings`
2. Under **Danger Zone**, click **Change visibility** and set to **Public**

Alternatively, if the repo is private, authenticate on Picasso:
```bash
singularity remote login --username Davidn1095 docker://ghcr.io
# Enter a GitHub Personal Access Token with read:packages scope
```
