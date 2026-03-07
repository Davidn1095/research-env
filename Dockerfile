FROM bioconductor/bioconductor_docker:3.18

LABEL maintainer="David Nunez"
LABEL description="Unified autoimmune-atlas R/Bioconductor + extended packages"
LABEL version="2.0.0"
LABEL org.opencontainers.image.source="https://github.com/Davidn1095/research-env"

# ============================================================================
# Environment variables
# ============================================================================
ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    R_LIBS_USER=/mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/R_overflow \
    PYTHONUSERBASE=/mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/py_overflow \
    DEBIAN_FRONTEND=noninteractive

ENV PATH="${PYTHONUSERBASE}/bin:${PATH}"

# ============================================================================
# LAYER 1: System dependencies
# ============================================================================
# Most dev libs (libcurl, libxml2, libssl, libpng, libtiff, etc.) are already
# in bioconductor_docker:3.18. Install only extras needed at compile time.
# ============================================================================
RUN set -e && \
    apt-get update && apt-get install -y --no-install-recommends \
        libgsl-dev \
        jags \
        libboost-dev \
        libboost-iostreams-dev \
        libprotobuf-dev protobuf-compiler \
        libglpk-dev \
        libgmp-dev \
        libmpfr-dev \
        libnode-dev \
        libgdal-dev libgeos-dev libproj-dev \
        libbz2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# LAYER 2: Python packages (minimal, for R interop via reticulate)
# ============================================================================
RUN set -e && \
    pip3 install --no-cache-dir \
        joblib==1.4.2 \
        numpy==1.26.4 \
        pandas==2.2.2 \
        pip==22.0.2 \
        python-dateutil==2.9.0.post0 \
        pytz==2024.1 \
        PyYAML==6.0.1 \
        scikit-learn==1.4.2 \
        scipy==1.13.0 \
        six==1.16.0 \
        threadpoolctl==3.5.0 \
        tzdata==2024.1

# ============================================================================
# LAYER 3: R CRAN packages (401 packages, version-pinned)
# ============================================================================
# Split into sub-layers to improve Docker cache efficiency on rebuilds.
# ============================================================================

# --- 3a: Core infrastructure + data manipulation ---
RUN set -e && Rscript -e ' \
    options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = 4L, warn = 1); \
    if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes"); \
    iv <- function(pkg, ver) { \
        remotes::install_version(pkg, version = ver, upgrade = "never", \
                                 quiet = TRUE, dependencies = FALSE) \
    }; \
    \
    ## Core infrastructure \
    iv("BH",             "1.84.0-0"); \
    iv("R6",             "2.5.1"); \
    iv("Rcpp",           "1.0.12"); \
    iv("RcppArmadillo",  "0.12.8.2.1"); \
    iv("RcppEigen",      "0.3.4.0.0"); \
    iv("RcppAnnoy",      "0.0.22"); \
    iv("RcppHNSW",       "0.6.0"); \
    iv("RcppML",         "0.3.7"); \
    iv("RcppProgress",   "0.4.2"); \
    iv("RcppTOML",       "0.2.3"); \
    iv("cpp11",          "0.5.3"); \
    iv("rlang",          "1.1.3"); \
    iv("cli",            "3.6.2"); \
    iv("glue",           "1.7.0"); \
    iv("vctrs",          "0.6.5"); \
    iv("pillar",         "1.9.0"); \
    iv("tibble",         "3.2.1"); \
    iv("generics",       "0.1.3"); \
    iv("backports",      "1.4.1"); \
    iv("crayon",         "1.5.2"); \
    iv("S7",             "0.2.1"); \
    iv("rprojroot",      "2.1.1"); \
    \
    ## Data manipulation \
    iv("dplyr",          "1.1.4"); \
    iv("tidyr",          "1.3.1"); \
    iv("tidyselect",     "1.2.1"); \
    iv("purrr",          "1.0.2"); \
    iv("forcats",        "1.0.1"); \
    iv("readr",          "2.1.6"); \
    iv("readxl",         "1.4.5"); \
    iv("haven",          "2.5.5"); \
    iv("modelr",         "0.1.11"); \
    iv("reprex",         "2.1.1"); \
    iv("rvest",          "1.0.5"); \
    iv("dbplyr",         "2.5.1"); \
    iv("dtplyr",         "1.3.2"); \
    iv("data.table",     "1.18.2.1"); \
    iv("tidyverse",      "2.0.0"); \
    iv("lubridate",      "1.9.4"); \
    iv("timechange",     "0.3.0"); \
    iv("hms",            "1.1.4"); \
    iv("tzdb",           "0.5.0"); \
    iv("vroom",          "1.7.0"); \
    iv("cellranger",     "1.1.0"); \
    iv("DBI",            "1.2.2"); \
    iv("RSQLite",        "2.3.6"); \
    iv("blob",           "1.2.4"); \
    iv("bit",            "4.0.5"); \
    iv("bit64",          "4.0.5"); \
    iv("plogr",          "0.2.0"); \
    iv("conflicted",     "1.2.0"); \
    iv("plyr",           "1.8.9"); \
    iv("reshape",        "0.8.9"); \
    iv("reshape2",       "1.4.4"); \
    iv("abind",          "1.4-5"); \
    iv("assertthat",     "0.2.1"); \
    iv("clock",          "0.7.4"); \
    iv("sparsevctrs",    "0.3.6"); \
    \
    ## String and text processing \
    iv("stringi",        "1.8.3"); \
    iv("stringr",        "1.5.1"); \
    iv("formatR",        "1.14"); \
    iv("selectr",        "0.5-1"); \
    iv("XML",            "3.99-0.16.1"); \
    iv("xml2",           "1.5.2"); \
    iv("rjson",          "0.2.21"); \
    iv("jsonlite",       "1.8.8"); \
    iv("yaml",           "2.3.8"); \
    \
    cat("\n=== CRAN layer 3a done ===\n") \
    '

# --- 3b: Plotting and visualization ---
RUN set -e && Rscript -e ' \
    options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = 4L, warn = 1); \
    iv <- function(pkg, ver) { \
        remotes::install_version(pkg, version = ver, upgrade = "never", \
                                 quiet = TRUE, dependencies = FALSE) \
    }; \
    \
    iv("colorspace",     "2.1-0"); \
    iv("munsell",        "0.5.1"); \
    iv("labeling",       "0.4.3"); \
    iv("farver",         "2.1.1"); \
    iv("scales",         "1.4.0"); \
    iv("gtable",         "0.3.6"); \
    iv("isoband",        "0.2.7"); \
    iv("ggplot2",        "4.0.1"); \
    iv("patchwork",      "1.3.2"); \
    iv("cowplot",        "1.2.0"); \
    iv("ggpubr",         "0.6.2"); \
    iv("ggsignif",       "0.6.4"); \
    iv("ggrepel",        "0.9.5"); \
    iv("ggridges",       "0.5.7"); \
    iv("ggrastr",        "1.0.2"); \
    iv("ggbeeswarm",     "0.7.2"); \
    iv("ggforce",        "0.4.2"); \
    iv("ggsci",          "4.2.0"); \
    iv("ggalluvial",     "0.12.5"); \
    iv("ggExtra",        "0.11.0"); \
    iv("ggfittext",      "0.10.3"); \
    iv("gggenes",        "0.6.0"); \
    iv("ggnetwork",      "0.5.14"); \
    iv("ggpp",           "0.6.0"); \
    iv("ggVennDiagram",  "1.5.7"); \
    iv("ggnewscale",     "0.4.10"); \
    iv("ggplotify",      "0.1.2"); \
    iv("ggfun",          "0.1.4"); \
    iv("ggraph",         "2.2.1"); \
    iv("scatterpie",     "0.2.2"); \
    iv("scattermore",    "1.2"); \
    iv("shadowtext",     "0.1.3"); \
    iv("corrplot",       "0.95"); \
    iv("pheatmap",       "1.0.13"); \
    iv("circlize",       "0.4.16"); \
    iv("gridExtra",      "2.3"); \
    iv("gridGraphics",   "0.5-1"); \
    iv("gridBase",       "0.4-7"); \
    iv("gridtext",       "0.1.5"); \
    iv("RColorBrewer",   "1.1-3"); \
    iv("viridis",        "0.6.5"); \
    iv("viridisLite",    "0.4.2"); \
    iv("png",            "0.1-8"); \
    iv("jpeg",           "0.1-11"); \
    iv("Cairo",          "1.6-2"); \
    iv("ragg",           "1.3.0"); \
    iv("svglite",        "2.2.2"); \
    iv("systemfonts",    "1.3.1"); \
    iv("textshaping",    "0.3.7"); \
    iv("plotly",         "4.10.4"); \
    iv("crosstalk",      "1.2.1"); \
    iv("htmlwidgets",    "1.6.4"); \
    iv("htmltools",      "0.5.8.1"); \
    iv("htmlTable",      "2.4.3"); \
    iv("vipor",          "0.4.7"); \
    iv("beeswarm",       "0.4.0"); \
    iv("polyclip",       "1.10-6"); \
    iv("tweenr",         "2.0.3"); \
    iv("gplots",         "3.3.0"); \
    iv("gtools",         "3.9.5"); \
    iv("caTools",        "1.18.3"); \
    iv("shape",          "1.4.6.1"); \
    iv("venn",           "1.12"); \
    iv("polylabelr",     "1.0.0"); \
    iv("shades",         "1.4.0"); \
    \
    cat("\n=== CRAN layer 3b done ===\n") \
    '

# --- 3c: Shiny, spatstat, Seurat extras ---
RUN set -e && Rscript -e ' \
    options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = 4L, warn = 1); \
    iv <- function(pkg, ver) { \
        remotes::install_version(pkg, version = ver, upgrade = "never", \
                                 quiet = TRUE, dependencies = FALSE) \
    }; \
    \
    ## Shiny and interactive \
    iv("shiny",          "1.8.1.1"); \
    iv("httpuv",         "1.6.15"); \
    iv("later",          "1.3.2"); \
    iv("promises",       "1.3.0"); \
    iv("miniUI",         "0.1.1.1"); \
    iv("sourcetools",    "0.1.7-1"); \
    iv("bslib",          "0.7.0"); \
    iv("sass",           "0.4.9"); \
    iv("jquerylib",      "0.1.4"); \
    iv("fontawesome",    "0.5.2"); \
    iv("shinyjs",        "2.1.1"); \
    iv("colourpicker",   "1.3.0"); \
    iv("DT",             "0.34.0"); \
    iv("visNetwork",     "2.1.4"); \
    \
    ## Seurat extras \
    iv("sctransform",    "0.4.3"); \
    iv("harmony",        "1.2.4"); \
    iv("Rtsne",          "0.17"); \
    iv("uwot",           "0.2.2"); \
    iv("RANN",           "2.6.2"); \
    iv("irlba",          "2.3.5.1"); \
    iv("RSpectra",       "0.16-1"); \
    iv("ica",            "1.0-3"); \
    iv("RhpcBLASctl",    "0.23-42"); \
    iv("sp",             "2.2-0"); \
    iv("fitdistrplus",   "1.2-6"); \
    iv("ids",            "1.0.1"); \
    iv("ROCR",           "1.0-12"); \
    iv("FNN",            "1.1.4"); \
    iv("sitmo",          "2.0.2"); \
    iv("dqrng",          "0.3.2"); \
    iv("fastDummies",    "1.7.5"); \
    iv("fastmatch",      "1.1-4"); \
    iv("RCurl",          "1.98-1.14"); \
    iv("bitops",         "1.0-7"); \
    iv("reticulate",     "1.44.1"); \
    iv("lazyeval",       "0.2.2"); \
    \
    ## Spatstat family (Seurat dependency) \
    iv("spatstat.utils",    "3.2-1"); \
    iv("spatstat.data",     "3.1-9"); \
    iv("spatstat.univar",   "3.1-6"); \
    iv("spatstat.geom",     "3.7-0"); \
    iv("spatstat.random",   "3.4-4"); \
    iv("spatstat.sparse",   "3.1-0"); \
    iv("spatstat.explore",  "3.7-0"); \
    \
    cat("\n=== CRAN layer 3c done ===\n") \
    '

# --- 3c-post: Upgrade Seurat to 5.4.0 (base image ships 5.0.3) ---
# All Seurat dependencies are now installed from layers 3a-3c.
# Remove old versions, reinstall exact versions, verify.
RUN set -e && Rscript -e ' \
    options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = 4L, warn = 1); \
    tryCatch(remove.packages("Seurat"), error = function(e) NULL); \
    tryCatch(remove.packages("SeuratObject"), error = function(e) NULL); \
    remotes::install_version("SeuratObject", version = "5.3.0", \
                             upgrade = "never", quiet = FALSE, dependencies = FALSE); \
    remotes::install_version("Seurat", version = "5.4.0", \
                             upgrade = "never", quiet = FALSE, dependencies = FALSE); \
    cat("SeuratObject", as.character(packageVersion("SeuratObject")), "\n"); \
    cat("Seurat", as.character(packageVersion("Seurat")), "\n"); \
    stopifnot(packageVersion("SeuratObject") == "5.3.0"); \
    stopifnot(packageVersion("Seurat") == "5.4.0") \
    '

# --- 3d: ML, statistics, network analysis ---
RUN set -e && Rscript -e ' \
    options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = 4L, warn = 1); \
    iv <- function(pkg, ver) { \
        remotes::install_version(pkg, version = ver, upgrade = "never", \
                                 quiet = TRUE, dependencies = FALSE) \
    }; \
    \
    ## ML / statistical modelling \
    iv("xgboost",        "3.1.3.1"); \
    iv("glmnet",         "4.1-10"); \
    iv("caret",          "7.0-1"); \
    iv("caretEnsemble",  "4.0.1"); \
    iv("randomForest",   "4.7-1.2"); \
    iv("ranger",         "0.18.0"); \
    iv("e1071",          "1.7-17"); \
    iv("kknn",           "1.4.1"); \
    iv("kernlab",        "0.9-32"); \
    iv("pROC",           "1.19.0.1"); \
    iv("PRROC",          "1.4"); \
    iv("MLmetrics",      "1.1.3"); \
    iv("ModelMetrics",   "1.2.2.2"); \
    iv("SHAPforxgboost", "0.2.0"); \
    iv("shapviz",        "0.10.3"); \
    iv("recipes",        "1.3.1"); \
    iv("hardhat",        "1.4.2"); \
    iv("gower",          "1.0.2"); \
    iv("ipred",          "0.9-15"); \
    iv("lava",           "1.8.2"); \
    iv("prodlim",        "2025.04.28"); \
    iv("proxy",          "0.4-29"); \
    iv("SQUAREM",        "2021.1"); \
    \
    ## Mixed models and inference \
    iv("lme4",           "1.1-38"); \
    iv("pbkrtest",       "0.5.5"); \
    iv("car",            "3.1-3"); \
    iv("carData",        "3.0-5"); \
    iv("rstatix",        "0.7.3"); \
    iv("mixtools",       "2.0.0"); \
    iv("emmeans",        "2.0.1"); \
    iv("estimability",   "1.5.1"); \
    iv("lmtest",         "0.9-40"); \
    iv("multcompView",   "0.1-10"); \
    iv("segmented",      "2.0-4"); \
    iv("minqa",          "1.2.8"); \
    iv("nloptr",         "2.2.1"); \
    iv("numDeriv",       "2016.8-1.1"); \
    iv("reformulas",     "0.4.3.1"); \
    iv("MatrixModels",   "0.5-4"); \
    iv("SparseM",        "1.84-2"); \
    iv("matrixStats",    "1.3.0"); \
    iv("quadprog",       "1.5-8"); \
    iv("broom",          "1.0.5"); \
    iv("Deriv",          "4.2.0"); \
    iv("doBy",           "4.7.1"); \
    iv("Formula",        "1.2-5"); \
    iv("statmod",        "1.5.0"); \
    iv("quantreg",       "6.1"); \
    iv("mvtnorm",        "1.2-4"); \
    iv("energy",         "1.7-11"); \
    iv("entropy",        "1.3.2"); \
    iv("minerva",        "1.5.10"); \
    \
    ## Network analysis (WGCNA etc.) \
    iv("WGCNA",          "1.73"); \
    iv("dynamicTreeCut", "1.63-1"); \
    iv("fastcluster",    "1.3.0"); \
    iv("igraph",         "2.2.1"); \
    iv("graphlayouts",   "1.1.1"); \
    iv("tidygraph",      "1.3.1"); \
    iv("network",        "1.19.0"); \
    iv("sna",            "2.8"); \
    iv("statnet.common", "4.13.0"); \
    \
    cat("\n=== CRAN layer 3d done ===\n") \
    '

# --- 3e: Remaining CRAN packages ---
RUN set -e && Rscript -e ' \
    options(repos = c(CRAN = "https://cloud.r-project.org"), Ncpus = 4L, warn = 1); \
    iv <- function(pkg, ver) { \
        remotes::install_version(pkg, version = ver, upgrade = "never", \
                                 quiet = TRUE, dependencies = FALSE) \
    }; \
    \
    ## Enrichment / pathway (CRAN portion) \
    iv("enrichR",        "3.4"); \
    iv("msigdbr",        "25.1.1"); \
    \
    ## Time series (forecast dependency) \
    iv("forecast",       "9.0.0"); \
    iv("fracdiff",       "1.5-3"); \
    iv("tseries",        "0.10-59"); \
    iv("TTR",            "0.24.4"); \
    iv("quantmod",       "0.4.28"); \
    iv("xts",            "0.14.1"); \
    iv("urca",           "1.3-4"); \
    iv("zoo",            "1.8-15"); \
    iv("timeDate",       "4052.112"); \
    iv("polynom",        "1.4-1"); \
    \
    ## Tree visualization (ggtree CRAN deps) \
    iv("ape",            "5.8"); \
    iv("aplot",          "0.2.2"); \
    iv("tidytree",       "0.4.6"); \
    iv("yulab.utils",    "0.1.4"); \
    \
    ## File I/O \
    iv("hdf5r",          "1.3.12"); \
    iv("restfulr",       "0.0.15"); \
    \
    ## Parallel / futures \
    iv("foreach",        "1.5.2"); \
    iv("iterators",      "1.0.14"); \
    iv("doParallel",     "1.0.17"); \
    iv("doRNG",          "1.8.6.2"); \
    iv("rngtools",       "1.5.2"); \
    iv("future",         "1.69.0"); \
    iv("future.apply",   "1.20.1"); \
    iv("parallelly",     "1.46.1"); \
    iv("listenv",        "0.10.0"); \
    iv("globals",        "0.18.0"); \
    iv("furrr",          "0.3.1"); \
    iv("progressr",      "0.18.0"); \
    iv("snow",           "0.4-4"); \
    iv("pbapply",        "1.7-4"); \
    iv("progress",       "1.2.3"); \
    \
    ## Google APIs \
    iv("gargle",         "1.6.1"); \
    iv("googledrive",    "2.1.2"); \
    iv("googlesheets4",  "1.1.2"); \
    iv("httr",           "1.4.7"); \
    iv("httr2",          "1.0.1"); \
    iv("curl",           "5.2.1"); \
    iv("openssl",        "2.1.2"); \
    \
    ## Logging and misc \
    iv("futile.logger",  "1.4.3"); \
    iv("futile.options",  "1.0.1"); \
    iv("lambda.r",       "1.2.4"); \
    iv("logger",         "0.4.1"); \
    iv("checkmate",      "2.3.3"); \
    iv("BBmisc",         "1.13.1"); \
    iv("GetoptLong",     "1.0.5"); \
    iv("GlobalOptions",  "0.1.2"); \
    iv("config",         "0.3.2"); \
    iv("here",           "1.0.2"); \
    iv("uuid",           "1.2-2"); \
    iv("digest",         "0.6.35"); \
    iv("ellipsis",       "0.3.2"); \
    iv("fansi",          "1.0.6"); \
    iv("prettyunits",    "1.2.0"); \
    iv("R.methodsS3",   "1.8.2"); \
    iv("R.oo",           "1.26.0"); \
    iv("R.utils",        "2.12.3"); \
    iv("locfit",         "1.5-9.9"); \
    \
    ## Documentation \
    iv("knitr",          "1.46"); \
    iv("xfun",           "0.49"); \
    iv("highr",          "0.10"); \
    iv("evaluate",       "0.23"); \
    iv("rmarkdown",      "2.26"); \
    iv("bookdown",       "0.46"); \
    iv("litedown",       "0.9"); \
    iv("markdown",       "2.0"); \
    iv("tinytex",        "0.50"); \
    iv("rbibutils",      "2.4.1"); \
    iv("Rdpack",         "2.6.5"); \
    iv("Hmisc",          "5.2-5"); \
    iv("xtable",         "1.8-4"); \
    \
    ## Spatial math (non-spatstat) \
    iv("deldir",         "2.0-4"); \
    iv("goftest",        "1.2-3"); \
    iv("tensor",         "1.5.1"); \
    iv("spam",           "2.11-3"); \
    iv("dotCall64",      "1.2"); \
    \
    ## Keras / TensorFlow (R interface) \
    iv("keras",          "2.16.0"); \
    iv("keras3",         "1.5.0"); \
    iv("tensorflow",     "2.20.0"); \
    iv("tfautograph",    "0.3.2"); \
    iv("tfruns",         "1.5.4"); \
    iv("zeallot",        "0.2.0"); \
    iv("tester",         "0.3.0"); \
    \
    ## GSL \
    iv("gsl",            "2.1-8"); \
    \
    ## Clustering \
    iv("mclust",         "6.1.2"); \
    iv("clue",           "0.3-65"); \
    iv("flashClust",     "1.01-2"); \
    iv("NMF",            "0.28"); \
    iv("registry",       "0.5-1"); \
    \
    ## Factor analysis \
    iv("factoextra",     "1.0.7"); \
    iv("FactoMineR",     "2.13"); \
    iv("ellipse",        "0.5.0"); \
    iv("leaps",          "3.2"); \
    iv("scatterplot3d",  "0.3-44"); \
    \
    ## ML other \
    iv("rsvd",           "1.0.5"); \
    iv("metrica",        "2.0.3"); \
    iv("microbenchmark", "1.5.0"); \
    iv("nycflights13",   "1.0.2"); \
    \
    ## Misc CRAN \
    iv("diagram",        "1.6.5"); \
    iv("admisc",         "0.39"); \
    iv("babelgene",      "22.9"); \
    iv("coda",           "0.19-4.1"); \
    iv("dendextend",     "1.19.1"); \
    iv("downloader",     "0.4"); \
    iv("expm",           "1.0-0"); \
    iv("filelock",       "1.0.3"); \
    iv("glasso",         "1.11"); \
    iv("gson",           "0.1.0"); \
    iv("otel",           "0.2.0"); \
    iv("rematch",        "2.0.0"); \
    iv("dotty",          "0.1.0"); \
    \
    ## Devtools ecosystem (pin versions) \
    iv("devtools",       "2.4.5"); \
    iv("pkgbuild",       "1.4.4"); \
    iv("pkgload",        "1.3.4"); \
    iv("pkgdown",        "2.0.9"); \
    iv("pkgconfig",      "2.0.3"); \
    iv("sessioninfo",    "1.2.2"); \
    iv("callr",          "3.7.6"); \
    iv("processx",       "3.8.4"); \
    iv("ps",             "1.7.6"); \
    iv("profvis",        "0.3.8"); \
    iv("remotes",        "2.5.0"); \
    iv("roxygen2",       "7.3.1"); \
    iv("testthat",       "3.2.1.1"); \
    iv("praise",         "1.0.0"); \
    iv("waldo",          "0.5.2"); \
    iv("diffobj",        "0.3.5"); \
    iv("brio",           "1.1.4"); \
    iv("usethis",        "2.2.3"); \
    iv("fs",             "1.6.3"); \
    iv("gert",           "2.0.1"); \
    iv("gh",             "1.4.1"); \
    iv("gitcreds",       "0.1.2"); \
    iv("credentials",    "2.0.1"); \
    iv("sys",            "3.4.2"); \
    iv("mime",           "0.12"); \
    iv("ini",            "0.3.1"); \
    iv("rcmdcheck",      "1.4.0"); \
    iv("rversions",      "2.1.2"); \
    iv("xopen",          "1.0.0"); \
    iv("urlchecker",     "1.0.1"); \
    iv("whisker",        "0.4.1"); \
    iv("rstudioapi",     "0.16.0"); \
    iv("downlit",        "0.4.3"); \
    iv("commonmark",     "1.9.1"); \
    iv("desc",           "1.4.3"); \
    iv("rematch2",       "2.1.2"); \
    iv("clipr",          "0.8.0"); \
    iv("rappdirs",       "0.3.3"); \
    iv("cachem",         "1.0.8"); \
    iv("memoise",        "2.0.1"); \
    iv("fastmap",        "1.1.1"); \
    iv("withr",          "3.0.0"); \
    iv("lifecycle",      "1.0.4"); \
    iv("magrittr",       "2.0.3"); \
    iv("littler",        "0.3.20"); \
    iv("docopt",         "0.7.1"); \
    iv("base64enc",      "0.1-3"); \
    iv("zip",            "2.3.1"); \
    \
    ## Packages in bioc docker base image — pin for reproducibility \
    iv("BiocManager",    "1.30.23"); \
    iv("askpass",        "1.2.0"); \
    iv("brew",           "1.0-10"); \
    iv("utf8",           "1.2.4"); \
    \
    cat("\n=== CRAN layer 3e done ===\n") \
    '

# ============================================================================
# LAYER 4: R Bioconductor packages (90 packages)
# ============================================================================

# --- 4a: Core infrastructure + genomics ---
RUN set -e && Rscript -e ' \
    options(Ncpus = 4L, warn = 1); \
    \
    BiocManager::install(c( \
        "BiocGenerics", "BiocVersion", "S4Vectors", "IRanges", \
        "GenomeInfoDb", "GenomeInfoDbData", "GenomicRanges", "Biobase", \
        "XVector", "zlibbioc", "S4Arrays", "SparseArray", \
        "MatrixGenerics", "SummarizedExperiment", "DelayedArray", \
        "DelayedMatrixStats", "HDF5Array", "Rhdf5lib", "rhdf5", \
        "rhdf5filters", "BiocParallel", "BiocIO", "BiocFileCache", \
        "BiocStyle", "AnnotationDbi", "AnnotationHub", "ExperimentHub", \
        "interactiveDisplayBase", "dir.expiry", "graph" \
    ), ask = FALSE, update = FALSE); \
    \
    BiocManager::install(c( \
        "Biostrings", "Rsamtools", "Rhtslib", "rtracklayer", \
        "GenomicAlignments" \
    ), ask = FALSE, update = FALSE); \
    \
    cat("\n=== Bioc layer 4a done ===\n") \
    '

# --- 4b: Single-cell + DE + enrichment ---
RUN set -e && Rscript -e ' \
    options(Ncpus = 4L, warn = 1); \
    \
    BiocManager::install(c( \
        "SingleCellExperiment", "scran", "scater", "scuttle", \
        "beachmat", "BiocNeighbors", "BiocSingular", "ScaledMatrix", \
        "sparseMatrixStats", "metapod", "bluster", "AUCell", \
        "UCell", "MAST", "SingleR", "celldex", \
        "scDblFinder", "miloR", "densvis" \
    ), ask = FALSE, update = FALSE); \
    \
    BiocManager::install(c( \
        "DESeq2", "edgeR", "limma" \
    ), ask = FALSE, update = FALSE); \
    \
    BiocManager::install(c( \
        "clusterProfiler", "DOSE", "enrichplot", "GOSemSim", \
        "fgsea", "GSVA", "GSEABase", "qvalue", "singscore" \
    ), ask = FALSE, update = FALSE); \
    \
    cat("\n=== Bioc layer 4b done ===\n") \
    '

# --- 4c: Annotation, trees, CCC, signatures, basilisk ---
RUN set -e && Rscript -e ' \
    options(Ncpus = 4L, warn = 1); \
    \
    BiocManager::install(c( \
        "org.Hs.eg.db", "GO.db", "HDO.db", "KEGGREST", "reactome.db" \
    ), ask = FALSE, update = FALSE); \
    \
    BiocManager::install(c( \
        "ggtree", "treeio" \
    ), ask = FALSE, update = FALSE); \
    \
    BiocManager::install(c( \
        "OmnipathR", "viper", "decoupleR" \
    ), ask = FALSE, update = FALSE); \
    \
    BiocManager::install(c( \
        "ComplexHeatmap", "EnhancedVolcano", "GeneOverlap", "GEOquery", \
        "affy", "affyio", "annotate", "impute", "preprocessCore", \
        "signatureSearch", "signatureSearchData" \
    ), ask = FALSE, update = FALSE); \
    \
    BiocManager::install(c( \
        "basilisk", "basilisk.utils", "zellkonverter" \
    ), ask = FALSE, update = FALSE); \
    \
    cat("\n=== Bioc layer 4c done ===\n") \
    '

# ============================================================================
# LAYER 5: R GitHub packages (4 packages, each in own layer for caching)
# ============================================================================

# --- 5a: CellChat v1.6.1 (pinned to master commit) ---
RUN set -e && Rscript -e ' \
    options(Ncpus = 4L, warn = 1); \
    devtools::install_github("sqjin/CellChat@e4f68625b074247d619c2e488d33970cc531e17c", \
                             upgrade = "never", quiet = TRUE); \
    cat("CellChat", as.character(packageVersion("CellChat")), "\n") \
    '

# --- 5b: SeuratDisk v0.0.0.9021 (pinned to master commit, no tags exist) ---
RUN set -e && Rscript -e ' \
    options(Ncpus = 4L, warn = 1); \
    devtools::install_github("mojaveazure/seurat-disk@877d4e18ab38c686f5db54f8cd290274ccdbe295", \
                             upgrade = "never", quiet = TRUE); \
    cat("SeuratDisk", as.character(packageVersion("SeuratDisk")), "\n") \
    '

# --- 5c: LIANA v0.1.14 (pinned to master commit, tag 0.1.14 does not exist) ---
RUN set -e && Rscript -e ' \
    options(Ncpus = 4L, warn = 1); \
    devtools::install_github("saezlab/liana@6cab46c54234f861ea176c3de77c4b8aa45ecb3d", \
                             upgrade = "never", quiet = TRUE); \
    cat("liana", as.character(packageVersion("liana")), "\n") \
    '

# --- 5d: hdWGCNA v0.4.09 (tag exists) ---
RUN set -e && Rscript -e ' \
    options(Ncpus = 4L, warn = 1); \
    devtools::install_github("smorabit/hdWGCNA@v0.4.09", \
                             upgrade = "never", quiet = TRUE); \
    cat("hdWGCNA", as.character(packageVersion("hdWGCNA")), "\n") \
    '

# ============================================================================
# LAYER 6: Cleanup
# ============================================================================
RUN rm -rf /tmp/* /var/tmp/* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["Rscript"]
