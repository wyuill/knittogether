#' Generate a quality check log for placeholder replacements (developer utility)
#'
#' @description
#' Internal developer-facing utility used by [replace_placeholders()] to compare current
#' placeholder code content against the latest logged state (CSV) and record
#' change metadata. Optionally generates an HTML report (Quarto + reactable)
#' from the same CSV.
#'
#' @param code_content
#'    A named list of content specifications and scalars, typically from `placeholder_map()`.
#' @param markdown_file
#'    Path to the markdown file used to extract nearby context for placeholders.
#' @param placeholder_prefix
#'    Prefix used for placeholders in the markdown. Defaults to `"placeholder_content"`.
#' @param validation_path
#'    Directory where outputs are saved (CSV, HTML). Defaults to `"validation"`.
#' @param log_file
#'    CSV log file name (within `validation_path`) to be generated and to read (if already exists). If `NULL` the log
#'    is not generated. Defaults to `"quality_log.csv"`.
#' @param html_file
#'    HTML report file name (within `validation_path`) to be generated. If this already exists it will be overwritten.
#'     If `NULL` the report is not generated. Default: `"validation.html"`.
#'
#' @return Invisibly returns the current validation data frame (including change flags).
#' @keywords internal
generate_quality_check <- function(
	code_content,
	markdown_file,
	placeholder_prefix = "placeholder_content",
	validation_path = "validation",
	log_file = "quality_log.csv",
	html_file = "validation.html"
) {
	validation_path <- normalizePath(validation_path, winslash = "/", mustWork = FALSE)

	# Create the validation directory if we will write anything there
	if (!is.null(log_file) || !is.null(html_file)) {
		dir.create(validation_path, recursive = TRUE, showWarnings = FALSE)
	}

	if (!is.null(log_file)) {
		log_file_name <- basename(log_file)
		log_file <- file.path(validation_path, log_file_name)
	}
	if (!is.null(html_file)) {
		html_file_name <- basename(html_file)
		html_file <- file.path(validation_path, html_file_name)
	}

	# Read markdown for snippet extraction (single string)
	md_text <- if (file.exists(markdown_file)) {
		paste(readLines(markdown_file, warn = FALSE), collapse = "\n")
	} else {
		""
	}

	timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")

	# Split scalars vs non-scalars
	id_scalars <- vapply(code_content, function(item) is.atomic(item) && length(item) == 1, logical(1))
	scalars <- code_content[id_scalars]
	nonscalar <- code_content[!id_scalars]

	# Helper to safely hash strings
	hash_str <- function(x) rlang::hash(paste0(x, collapse = ""))

	# Build rows for non-scalar content
	rows <- lapply(nonscalar, function(s) {
		id <- if (!is.null(s$placeholder_id)) {
			s$placeholder_id
		} else if (!is.null(s$id)) {
			s$id
		} else {
			NA_character_
		}
		desc <- if (!is.null(s$description)) s$description else NA_character_
		ctype <- if (!is.null(s$content_type)) s$content_type else NA_character_
		omode <- if (!is.null(s$output_mode)) s$output_mode else NA_character_

		content_str <- paste0(s$content_expr, collapse = "")

		# Extract a snippet around the first occurrence of 'placeholder_prefix_id'
		placeholder_key <- paste0(placeholder_prefix, "_", id)
		pos <- regexpr(placeholder_key, md_text, fixed = TRUE)

		placeholder_snippet <- if (pos[1] > 0) {
			before <- 300L
			after <- 300L
			start <- max(1L, pos[1] - before)
			end <- min(nchar(md_text), pos[1] + attr(pos, "match.length") + after)
			substring(md_text, start, end)
		} else {
			NA_character_
		}

		data.frame(
			timestamp = timestamp,
			placeholder_id = as.character(id),
			description = as.character(desc),
			content_type = as.character(ctype),
			output_mode = as.character(omode),
			content_preview = if (!is.na(content_str)) substr(content_str, 1, 400) else NA_character_,
			content_full = content_str,
			code_hash = hash_str(content_str),
			placeholder_snippet = placeholder_snippet,
			stringsAsFactors = FALSE
		)
	})

	df_current <- if (length(rows)) {
		dplyr::bind_rows(rows)
	} else {
		data.frame(
			timestamp = character(),
			placeholder_id = character(),
			description = character(),
			content_type = character(),
			output_mode = character(),
			content_preview = character(),
			content_full = character(),
			code_hash = character(),
			placeholder_snippet = character(),
			stringsAsFactors = FALSE
		)
	}

	# Add scalars as rows too
	if (length(scalars) > 0) {
		scalar_rows <- lapply(names(scalars), function(name) {
			val_chr <- if (!is.null(scalars[[name]])) as.character(scalars[[name]]) else NA_character_
			data.frame(
				timestamp = timestamp,
				placeholder_id = as.character(name),
				description = NA_character_,
				content_type = NA_character_,
				output_mode = NA_character_,
				content_preview = if (!is.na(val_chr)) substr(val_chr, 1, 400) else NA_character_,
				content_full = val_chr,
				code_hash = hash_str(val_chr),
				placeholder_snippet = NA_character_,
				stringsAsFactors = FALSE
			)
		})
		df_current <- dplyr::bind_rows(df_current, dplyr::bind_rows(scalar_rows))
	}

	# Load existing CSV (if any) and compute last-known hash per placeholder
	if (!is.null(log_file) && file.exists(log_file)) {
		df_log <- tryCatch(
			utils::read.csv(log_file, stringsAsFactors = FALSE),
			error = function(e) {
				cli::cli_alert_warning("Existing log file could not be read; treating as empty log.")
				data.frame()
			}
		)

		# Ensure needed cols exist; if malformed, proceed as empty historical log
		required_cols <- c("timestamp", "placeholder_id", "code_hash")
		missing_cols <- setdiff(required_cols, names(df_log))

		if (length(missing_cols)) {
			cli::cli_alert_warning(
				paste0(
					"Existing log file is missing required columns (",
					paste(missing_cols, collapse = ", "),
					"); treating as empty log."
				)
			)
			df_prev <- data.frame(placeholder_id = character(), code_hash.prev = character(), stringsAsFactors = FALSE)
		} else {
			# Keep latest row per placeholder_id by timestamp
			df_prev <- df_log %>%
				dplyr::arrange(dplyr::desc(.data$timestamp)) %>%
				dplyr::distinct(.data$placeholder_id, .keep_all = TRUE) %>%
				dplyr::rename(code_hash.prev = "code_hash") %>%
				dplyr::select(dplyr::all_of(c("placeholder_id", "code_hash.prev")))
		}
	} else {
		df_prev <- data.frame(placeholder_id = character(), code_hash.prev = character(), stringsAsFactors = FALSE)
	}

	# Join and mark changes
	df_compare <- df_current %>%
		dplyr::left_join(df_prev, by = "placeholder_id") %>%
		dplyr::mutate(
			changed_code = dplyr::case_when(
				is.na(.data$code_hash.prev) ~ TRUE, # new placeholder
				.data$code_hash != .data$code_hash.prev ~ TRUE, # changed
				TRUE ~ FALSE
			),
			change_summary = dplyr::if_else(.data$changed_code, "code", "none")
		) %>%
		dplyr::select(dplyr::all_of(c(
			"timestamp",
			"placeholder_id",
			"description",
			"content_type",
			"output_mode",
			"content_preview",
			"code_hash",
			"changed_code",
			"change_summary"
		)))

	# Append to CSV log (create if missing) unless log_file is NULL
	if (!is.null(log_file)) {
		if (!file.exists(log_file)) {
			utils::write.csv(df_compare, log_file, row.names = FALSE)
		} else {
			utils::write.table(df_compare, log_file, sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE)
		}
	}

	# Optionally render HTML report
	if (!is.null(html_file) && rlang::is_installed(c("quarto", "reactable", "withr", "readr", "dplyr"))) {
		qmd_text <- r"(
      ---
      title: "Quality check log"
      format:
        html:
           embed-resources: true
           page-layout: full
      execute:
        echo: false
        warning: false
        message: false
      ---

      ```{r}
      library(readr)
      library(dplyr)
      library(reactable)

      log <- read_csv("QUALITY_LOG_PLACEHOLDER", col_types = cols(
        timestamp = col_character(),
        placeholder_id = col_character(),
        description = col_character(),
        content_type = col_character(),
        output_mode = col_character(),
        content_preview = col_character(),
        code_hash = col_character(),
        changed_code = col_logical(),
        change_summary = col_character()
      ))

      log %>%
        arrange(desc(timestamp)) %>%
        reactable(
          filterable = TRUE,
          searchable = TRUE,
          defaultPageSize = 25,
          columns = list(
            timestamp = colDef(name = "Time"),
            placeholder_id = colDef(name = "Placeholder"),
            description = colDef(name = "Description"),
            content_type = colDef(name = "Type"),
            output_mode = colDef(name = "Mode"),
            content_preview = colDef(name = "Preview"),
            change_summary = colDef(name = "Change")
          ),
          rowStyle = JS("function(rowInfo) {
            if (rowInfo.values.change_summary !== \'none\') {
              return { background: \'#fff7e6\' };
            }
            return null;
          }")
        )
		)"
		qmd_path <- file.path(validation_path, "quality_log.qmd")
		csv_basename <- if (!is.null(log_file)) basename(log_file) else "quality_log.csv"
		qmd_text <- sub("QUALITY_LOG_PLACEHOLDER", csv_basename, qmd_text, fixed = TRUE)
		writeLines(qmd_text, qmd_path)

		# Render within validation_path so all relative paths work
		withr::with_dir(validation_path, {
			quarto::quarto_render(input = basename(qmd_path), output_file = basename(html_file), quiet = TRUE)
		})
	} else {
		cli::cli_alert_warning(
			"Packages 'quarto', 'reactable', 'withr', 'readr', 'dplyr' not all installed. Skipping HTML report."
		)
	}

	invisible(df_compare)
}
