#' @noRd
#' @description This function checks Pandoc availability and version requirements when the package is attached.
.onAttach <- function(libname, pkgname) {
	pandoc_min_version <- numeric_version("3.8.3")

	pandoc_default <- tryCatch(pandoc::pandoc_version("default"), error = function(e) numeric_version("0"))

	pandoc_latest <- tryCatch(pandoc::pandoc_version("latest"), error = function(e) numeric_version("0"))

	if (pandoc_default < pandoc_min_version) {
		if (pandoc_latest < pandoc_min_version) {
			cli::cli_inform(
				paste(
					"There is no version of pandoc that meets requirements. Some functions may not work as expected.\nYou can",
					"update your version of pandoc by installing the {.pkg pandoc} package and running",
					"{.run pandoc::pandoc_install()}.\nYou may need to tell R about this new version by running",
					"{.run pandoc::pandoc_activate()}."
				),
				class = "packageStartupMessage"
			)
		} else {
			cli::cli_inform(
				paste(
					"The default version of pandoc does not meet requirements but a version that does is installed.\nYou may need",
					"to make this version known to R by installing the {.pkg pandoc} package and running {.run pandoc::pandoc_activate()}."
				),
				class = "packageStartupMessage"
			)
		}
	}
}
