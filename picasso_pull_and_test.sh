#!/bin/bash
#
# Pull the unified container from GHCR and run smoke tests on Picasso.
#
# Usage:
#   module load singularity/3.7.2
#   bash picasso_pull_and_test.sh
#
# Must be run on the LOGIN NODE (compute nodes have no internet).
#
set -euo pipefail

IMAGE="docker://ghcr.io/davidn1095/research-env:2026.03"
SIF="${HOME}/research-env_2026.03.sif"
CONTAINERS_DIR="/mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/containers"
BIND_OPTS="--bind /mnt:/mnt,/mnt2:/mnt2,/localscratch:/localscratch"

echo "============================================================"
echo "Pulling container from GHCR..."
echo "  Source: ${IMAGE}"
echo "  Target: ${SIF}"
echo "============================================================"

singularity pull "${SIF}" "${IMAGE}"

echo ""
echo "============================================================"
echo "Running smoke tests..."
echo "============================================================"

PASS=0
FAIL=0
TESTS=0

run_test() {
    local name="$1"
    shift
    TESTS=$((TESTS + 1))
    echo -n "  ${name}... "
    if output=$("$@" 2>&1); then
        echo "PASS (${output})"
        PASS=$((PASS + 1))
    else
        echo "FAIL"
        echo "    Output: ${output}"
        FAIL=$((FAIL + 1))
    fi
}

EXEC="singularity exec ${BIND_OPTS} ${SIF}"

run_test "Python version"     ${EXEC} python3 --version
run_test "R version"          ${EXEC} R --version
run_test "Seurat"             ${EXEC} Rscript -e "library(Seurat); cat(paste('v', packageVersion('Seurat')))"
run_test "LIANA"              ${EXEC} Rscript -e "library(liana); cat(paste('v', packageVersion('liana')))"
run_test "DESeq2"             ${EXEC} Rscript -e "library(DESeq2); cat(paste('v', packageVersion('DESeq2')))"
run_test "xgboost"            ${EXEC} Rscript -e "library(xgboost); cat(paste('v', packageVersion('xgboost')))"
run_test "CellChat"           ${EXEC} Rscript -e "library(CellChat); cat(paste('v', packageVersion('CellChat')))"
run_test "hdWGCNA"            ${EXEC} Rscript -e "library(hdWGCNA); cat(paste('v', packageVersion('hdWGCNA')))"
run_test "ComplexHeatmap"     ${EXEC} Rscript -e "library(ComplexHeatmap); cat(paste('v', packageVersion('ComplexHeatmap')))"
run_test "SingleR"            ${EXEC} Rscript -e "library(SingleR); cat(paste('v', packageVersion('SingleR')))"
run_test "R package count"    ${EXEC} Rscript -e "cat(length(installed.packages()[,1]), 'R packages installed')"
run_test "Python pkg count"   ${EXEC} sh -c "pip3 list --format=freeze 2>/dev/null | wc -l | tr -d ' '"
run_test "R_LIBS_USER env"    ${EXEC} Rscript -e "cat(Sys.getenv('R_LIBS_USER'))"
run_test "numpy"              ${EXEC} python3 -c "import numpy; print('v' + numpy.__version__)"
run_test "scikit-learn"       ${EXEC} python3 -c "import sklearn; print('v' + sklearn.__version__)"

echo ""
echo "============================================================"
echo "RESULTS: ${PASS}/${TESTS} passed, ${FAIL} failed"
echo "============================================================"

if [[ ${FAIL} -eq 0 ]]; then
    echo ""
    echo "ALL TESTS PASSED"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Copy to containers directory:"
    echo "     cp ${SIF} ${CONTAINERS_DIR}/research-env_2026.03.sif"
    echo ""
    echo "  2. Create overflow directories:"
    echo "     mkdir -p /mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/R_overflow"
    echo "     mkdir -p /mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/py_overflow"
    echo ""
    echo "  3. Update your scripts — replace:"
    echo "     OLD: davidn1095_autoimmune_atlas.sif"
    echo "     NEW: research-env_2026.03.sif"
    echo "     And REMOVE: --env R_LIBS_USER=... (it's now baked in)"
    echo ""
    echo "  4. Once fully validated, clean up:"
    echo "     rm ${CONTAINERS_DIR}/davidn1095_autoimmune_atlas.sif"
    echo "     rm -rf /mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/R_4.3.3"
    echo "     rm -rf /mnt2/fscratch/users/fqm_235_genyo/davidnunez/singularity/conda_envs/basilisk"
    echo ""
    exit 0
else
    echo ""
    echo "SOME TESTS FAILED — review output above before deploying."
    exit 1
fi
