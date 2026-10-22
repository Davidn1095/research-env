# Load every R package the atlas uses; print one "PKG <name> <version>" line each.
# Exits non-zero if any package fails to load or a required function/argument is missing.
pkgs <- c("Seurat", "SeuratObject", "Matrix", "hdf5r", "reticulate", "pROC", "future",
          "glmnet", "ranger", "xgboost", "openxlsx2", "msigdbr",
          "ggplot2", "cowplot", "patchwork", "ggrepel", "ggrastr", "ggchicklet", "circlize",
          "magick", "png", "scales", "gtable", "dplyr", "tidyr", "readr", "tibble",
          "SingleR", "celldex", "scDblFinder", "decontX", "DESeq2", "fgsea", "limma",
          "clusterProfiler", "org.Hs.eg.db", "AnnotationDbi", "SingleCellExperiment",
          "SummarizedExperiment", "S4Vectors", "BiocParallel", "ExperimentHub",
          "AnnotationHub", "ComplexHeatmap", "BiocManager")
fail <- character()
for (p in pkgs) {
  ok <- suppressPackageStartupMessages(requireNamespace(p, quietly = TRUE))
  if (ok) cat("PKG", p, as.character(packageVersion(p)), "\n") else { cat("FAIL", p, "\n"); fail <- c(fail, p) }
}
cat("PKG R", paste(R.version$major, R.version$minor, sep = "."), "\n")
cat("PKG Bioconductor", as.character(BiocManager::version()), "\n")
# Functions and arguments the decisions rely on
chk <- list(
  "decontX::decontX has 'background'" = local({
    f <- tryCatch(methods::getMethod("decontX", "SingleCellExperiment", where = asNamespace("decontX")),
                  error = function(e) tryCatch(getS3method("decontX", "SingleCellExperiment", envir = asNamespace("decontX")),
                                               error = function(e) decontX::decontX))
    "background" %in% names(formals(f)) }),
  "scDblFinder has 'dbr'"             = "dbr" %in% names(formals(scDblFinder::scDblFinder)),
  "Seurat::AddModuleScore exists"     = is.function(Seurat::AddModuleScore),
  "fgsea::fgsea exists"               = is.function(fgsea::fgsea),
  "SingleR::SingleR exists"           = is.function(SingleR::SingleR),
  "DESeq2::DESeq exists"              = is.function(DESeq2::DESeq))
for (n in names(chk)) { cat(if (isTRUE(chk[[n]])) "CHECK OK  " else "CHECK FAIL", n, "\n"); if (!isTRUE(chk[[n]])) fail <- c(fail, n) }
# reticulate must see the image's Python 3.12
py <- reticulate::py_config(); cat("CHECK reticulate python", py$python, py$version, "\n")
if (!startsWith(as.character(py$version), "3.12")) fail <- c(fail, "reticulate python")
if (length(fail)) { cat("FAILED:", paste(fail, collapse = ", "), "\n"); quit(status = 1) }
cat("ALL R LOAD TESTS PASSED\n")
