# Run this following line if testing code without calling the PushToPSQL function
# df <- df_ALL

PushToPSQL <- function(df, save_tables_flag, DB_selected) {
  # setwd("~/Box Sync/P722 - MRRIC AM Support/Working Docs/P722 - HydroViz/hydroviz_R_code")
  
  if (!exists("save_tables_flag")) {save_tables_flag <- "no"}
      
  if (!"RPostgreSQL" %in% rownames(installed.packages())) {
    install.packages("RPostgreSQL")
  }
  
  if (!"dotenv" %in% rownames(installed.packages())) {
    install.packages("dotenv")
  }
  
  library("RPostgreSQL")
  library("dotenv")
  
  # loads the PostgreSQL driver
  driver <- dbDriver("PostgreSQL")
  
  # Load environment variables
  load_dot_env(file = ".env") # Loads variables from .env into R environment
  
  # creates a connection to the postgres database
  if (DB_selected == "Production DB") {
    message("**** Inserting into Production DB ****")
    
    connection <- dbConnect(
      driver,
      dbname = Sys.getenv("dbnameprod"),
      host = Sys.getenv("prodhost"),
      port = Sys.getenv("port"),
      user = Sys.getenv("user"),
      password = Sys.getenv("password")
    )
  } else if (DB_selected == "Testing DB") {
    message("**** Inserting into Testing DB ****")
    
    connection <- dbConnect(
      driver,
      dbname = Sys.getenv("dbnametest"),
      host = Sys.getenv("testhost"),
      port = Sys.getenv("port"),
      user = Sys.getenv("user"),
      password = Sys.getenv("password")
    )
  } else {
    message(" DB NAME NOT RECOGNIZED - STOPPING PushToPSQL")
    return()
  }
  
  message(" ")
  message("-------------------------")
  message("*** INSERTING INTO DB ***")
  message("-------------------------")
  message(" ")
  
  # Start timer
  SQL_module_start <- Sys.time()
  
  ## -----------------------
  ## Build ALTERNATIVES table
  ## -----------------------
  
  # Get alternatives data from the df
  LOCAL_alternatives <- data.frame(dplyr::distinct(df, alternative))
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_alternatives <- dbReadTable(connection, "alternatives")
  
  # 2 - remove existing values from the dataframe
  # The following will find, for each row of LOCAL_alternatives, the row number in DB_alternatives where it is found
  
  db_matches <-
    match(LOCAL_alternatives$alternative,
          DB_alternatives$alternative)
  num_df <- length(LOCAL_alternatives$alternative)
  
  # if a row in the returned array is NA, then the corresponding value in LOCAL_alternatives does not exist in DB_alternatives
  # Keep only the rows in LOCAL_alternatives that are 'NA' - meaning, they are not already in the DB
  
  to_insert <- filter(LOCAL_alternatives, is.na(db_matches))
  ALTS_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  
  # 3 - dbWriteTable to append the new values
  
  
  if (num_insert > 0) {
    dbWriteTable(
      connection,
      "alternatives",
      to_insert,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    ) # to protect current values
    message(
      c(
        num_df,
        " ALTERNATIVES in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      )
    )
    
    # ***********************
    DB_alternatives_after <- dbReadTable(connection, "alternatives")
    # ***********************
    
    
  } else {
    message(
      c(
        num_df,
        " ALTERNATIVES in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      )
    )
  }
  
  
  
  ## -----------------------
  ## Build SOURCES table
  ## -----------------------
  
  # Get data from the df
  LOCAL_sources <- data.frame(dplyr::distinct(df, source))
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_sources <- dbReadTable(connection, "sources")
  
  # 2 - remove existing values from the dataframe
  db_matches <- match(LOCAL_sources$source, DB_sources$source)
  num_df <- length(LOCAL_sources$source)
  
  to_insert <- filter(LOCAL_sources, is.na(db_matches))
  SOURCES_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  
  # 3 - dbWriteTable to append the new values
  if (num_insert > 0) {
    dbWriteTable(
      connection,
      "sources",
      to_insert,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    message(c(
      num_df,
      " SOURCES in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
  } else {
    message(c(
      num_df,
      " SOURCES in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
  }
  
  ## -----------------------
  ## Build TYPES table
  ## -----------------------
  
  # Get data from the df
  LOCAL_types <-
    data.frame(dplyr::distinct(df, type, units, measure))
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_types <- dbReadTable(connection, "types")
  
  # 2 - remove existing values from the dataframe
  db_matches <- match(LOCAL_types$type, DB_types$type)
  num_df <- length(LOCAL_types$type)
  
  to_insert <- filter(LOCAL_types, is.na(db_matches))
  TYPES_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  
  # 3 - dbWriteTable to append the new values
  if (num_insert > 0) {
    dbWriteTable(
      connection,
      "types",
      to_insert,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    message(c(
      num_df,
      " TYPES in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
  } else {
    message(c(
      num_df,
      " TYPES in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
  }
  
  
  
  
  ## -----------------------
  ## Build RIVERS table
  ## -----------------------
  
  LOCAL_rivers <- data.frame(dplyr::distinct(df, river))
  LOCAL_rivers$river <- as.character(LOCAL_rivers$river)
  # LOCAL_rivers[3,] <- "TEST"
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_rivers <- dbReadTable(connection, "rivers")
  
  # 2 - remove existing values from the dataframe
  db_matches <- match(LOCAL_rivers$river, DB_rivers$river)
  num_df <- length(LOCAL_rivers$river)
  
  to_insert <- filter(LOCAL_rivers, is.na(db_matches))
  RIVERS_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  
  # 3 - dbWriteTable to append the new values
  if (num_insert > 0) {
    dbWriteTable(
      connection,
      "rivers",
      to_insert,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    message(c(
      num_df,
      " RIVERS in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
  } else {
    message(c(
      num_df,
      " RIVERS in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
  }
  
  ## -----------------------
  ## Build LOCATIONS table
  ## -----------------------
  
  LOCAL_locations <- data.frame(dplyr::distinct(df, location))
  LOCAL_locations$location <- as.character(LOCAL_locations$location)
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_locations <- dbReadTable(connection, "locations")
  DB_locations$location <- as.character(DB_locations$location)
  
  # 2 - remove existing values from the dataframe
  db_matches <-
    match(LOCAL_locations$location, DB_locations$location)
  num_df <- length(LOCAL_locations$location)
  
  to_insert <- filter(LOCAL_locations, is.na(db_matches))
  LOCATIONS_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  #
  #
  # to_insert[1,] <- "ANOTHER"
  # colnames(to_insert) <- "location"
  
  # 3 - dbWriteTable to append the new values
  if (num_insert > 0) {
    RPostgreSQL::dbWriteTable(
      connection,
      "locations",
      to_insert,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    message(
      c(
        num_df,
        " LOCATIONS in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      )
    )
  } else {
    message(
      c(
        num_df,
        " LOCATIONS in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      )
    )
  }
  
  
  ## -----------------------
  ## Build MONTHS table
  ## -----------------------
  
  distinctDates <- data.frame(dplyr::distinct(df, date))
  LOCAL_months <-
    data.frame(month_name = unique(months(distinctDates$date)))
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_months <- dbReadTable(connection, "months")
  
  # 2 - remove existing values from the dataframe
  db_matches <-
    match(as.character(LOCAL_months$month_name),
          DB_months$month_name)
  num_df <- length(LOCAL_months$month_name)
  
  to_insert <- filter(LOCAL_months, is.na(db_matches))
  # to_insert$date <- as.character(to_insert$date) # Change date to character to put in DB
  MONTHS_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  
  # 3 - dbWriteTable to append the new values
  if (num_insert > 0) {
    result = tryCatch({
      RPostgreSQL::dbWriteTable(
        connection,
        "months",
        to_insert,
        row.names = FALSE,
        append = TRUE,
        overwrite = FALSE
      )
      message(c(
        num_df,
        " MONTHs in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      ))
    }, error = function(e) {
      message ("ERROR in months table insertion:")
      message (e)
    })
  } else {
    message(c(
      num_df,
      " MONTHs in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
  }
  
  ## -----------------------
  ## Build MODELED_DATES table
  ## -----------------------
  
  LOCAL_modeled_dates <- data.frame(dplyr::distinct(df, date))
  # LOCAL_modeled_dates$date <- as.character(LOCAL_modeled_dates$date)
  
  LOCAL_modeled_dates$year <-
    lubridate::year(LOCAL_modeled_dates$date)
  LOCAL_modeled_dates$month <-
    lubridate::month(LOCAL_modeled_dates$date)
  LOCAL_modeled_dates$day <-
    lubridate::day(LOCAL_modeled_dates$date)
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_modeled_dates <- dbReadTable(connection, "modeled_dates")
  
  # 2 - remove existing values from the dataframe
  db_matches <-
    match(as.character(LOCAL_modeled_dates$date),
          DB_modeled_dates$date)
  num_df <- length(LOCAL_modeled_dates$date)
  
  to_insert <- filter(LOCAL_modeled_dates, is.na(db_matches))
  to_insert$date <-
    as.character(to_insert$date) # Change date to character to put in DB
  MODLED_DATES_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  
  # 3 - dbWriteTable to append the new values
  
  if (num_insert > 0) {
    result = tryCatch({
      RPostgreSQL::dbWriteTable(
        connection,
        "modeled_dates",
        to_insert,
        row.names = FALSE,
        append = TRUE,
        overwrite = FALSE
      )
      message(
        c(
          num_df,
          " MODELED_DATES in df, ",
          num_dups,
          " duplicates, ",
          num_insert,
          " inserted in DB"
        )
      )
    }, error = function(e) {
      message ("ERROR in modeled_dates table insertion:")
      message (e)
    })
  } else {
    message(
      c(
        num_df,
        " MODELED_DATES in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      )
    )
  }
  
  ## -----------------------
  ## Build YEAR_DATES table
  ## -----------------------
  
  # Prep one year of dates to insert in DB
  one_year <- df[year(df$date) == 1931, ]$date
  LOCAL_year_dates <- data.frame(id = 1:365)
  LOCAL_year_dates$month_name <- months(unique(one_year))
  LOCAL_year_dates$month <-
    as.integer(format(unique(one_year), "%m"))
  LOCAL_year_dates$day <- lubridate::day(unique(one_year))
  
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_year_dates <- dbReadTable(connection, "year_dates")
  
  # 2 - remove existing values from the dataframe
  db_matches <-
    match(as.character(LOCAL_year_dates$id), DB_year_dates$id)
  num_df <- length(LOCAL_year_dates$id)
  
  to_insert <- filter(LOCAL_year_dates, is.na(db_matches))
  YEAR_DATES_inserted <- to_insert
  num_insert <- length(to_insert[[1]])
  num_dups <- num_df - num_insert
  
  # 3 - dbWriteTable to append the new values
  
  if (num_insert > 0) {
    RPostgreSQL::dbWriteTable(
      connection,
      "year_dates",
      to_insert,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    message(
      c(
        num_df,
        " YEAR_DATES in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      )
    )
  } else {
    message(
      c(
        num_df,
        " YEAR_DATES in df, ",
        num_dups,
        " duplicates, ",
        num_insert,
        " inserted in DB"
      )
    )
  }
  
  
  
  ## -----------------------
  ## Build DATA_BRIDGE table
  ## -----------------------
  
  # UPDATE LOCAL COPY OF TABLES (since they may have been updated above)
  DB_alternatives <- dbReadTable(connection, "alternatives")
  DB_locations <- dbReadTable(connection, "locations")
  DB_rivers <- dbReadTable(connection, "rivers")
  DB_sources <- dbReadTable(connection, "sources")
  DB_types <- dbReadTable(connection, "types")
  DB_modeled_dates <- dbReadTable(connection, "modeled_dates")
  DB_year_dates <- dbReadTable(connection, "year_dates")
  
  message("Starting DATA_BRIDGE")
  
  bridge_table_temp <- df
  
  # Alternative ids
  index <-
    match(
      bridge_table_temp$alternative,
      DB_alternatives$alternative,
      nomatch = NA_integer_,
      incomparables = NULL
    )
  bridge_table_temp$alternative <- DB_alternatives$id[index]
  bridge_table_temp <-
    dplyr::rename(bridge_table_temp, alternative_id = alternative)
  
  # Type ids
  index <-
    match(
      bridge_table_temp$type,
      DB_types$type,
      nomatch = NA_integer_,
      incomparables = NULL
    )
  bridge_table_temp$type <- DB_types$id[index]
  bridge_table_temp <-
    dplyr::rename(bridge_table_temp, type_id = type)
  
  # Source ids
  index <-
    match(
      bridge_table_temp$source,
      DB_sources$source,
      nomatch = NA_integer_,
      incomparables = NULL
    )
  bridge_table_temp$source <- DB_sources$id[index]
  bridge_table_temp <-
    dplyr::rename(bridge_table_temp, source_id = source)
  
  # River ids
  index <-
    match(
      bridge_table_temp$river,
      DB_rivers$river,
      nomatch = NA_integer_,
      incomparables = NULL
    )
  bridge_table_temp$river <- DB_rivers$id[index]
  bridge_table_temp <-
    dplyr::rename(bridge_table_temp, river_id = river)
  
  # Location ids
  index <-
    match(
      bridge_table_temp$location,
      DB_locations$location,
      nomatch = NA_integer_,
      incomparables = NULL
    )
  bridge_table_temp$location <- DB_locations$id[index]
  bridge_table_temp <-
    dplyr::rename(bridge_table_temp, location_id = location)
  
  # Create bridge_table
  index <-
    match(
      c(
        "alternative_id",
        "type_id",
        "source_id",
        "river_id",
        "location_id"
      ),
      colnames(bridge_table_temp),
      nomatch = NA_integer_,
      incomparables = NULL
    )
  LOCAL_data_bridge <- bridge_table_temp[, index]
  
  LOCAL_data_bridge <- unique(LOCAL_data_bridge)
  rownames(LOCAL_data_bridge) <-
    seq(length = nrow(LOCAL_data_bridge))
  LOCAL_data_bridge <-
    cbind(id = rownames(LOCAL_data_bridge), LOCAL_data_bridge)
  
  # Build CODE
  bt <- LOCAL_data_bridge
  LOCAL_data_bridge$code <-
    paste(bt$alternative_id,
          bt$type_id,
          bt$source_id,
          bt$river_id,
          bt$location_id)
  
  
  # INSERT UNIQUE data_bridge values into DB
  # 1 - query the table to see which values exist in the DB compared to my dataframe
  DB_data_bridge <- dbReadTable(connection, "data_bridge")
  
  # 2 - remove existing values from the dataframe
  db_matches <-
    match(as.character(LOCAL_data_bridge$code), DB_data_bridge$code)
  num_df <- length(LOCAL_data_bridge$id)
  
  L_data_bridge_NOid <-
    dplyr::select(LOCAL_data_bridge,
                  alternative_id,
                  type_id,
                  source_id,
                  river_id,
                  location_id,
                  code)
  
  data_to_insert <- filter(L_data_bridge_NOid, is.na(db_matches))
  DATA_BRIDGE_inserted <- data_to_insert
  num_to_insert <- length(data_to_insert[[1]])
  num_dups <- num_df - num_to_insert
  
  # 3 - dbWriteTable to append the new values
  
  if (num_to_insert > 0) {
    RPostgreSQL::dbWriteTable(
      connection,
      "data_bridge",
      data_to_insert,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    message(
      c(
        num_df,
        " DATA_BRIDGEs in df, ",
        num_dups,
        " duplicates, ",
        num_to_insert,
        " inserted in DB"
      )
    )
  } else {
    message(
      c(
        num_df,
        " DATA_BRIDGEs in df, ",
        num_dups,
        " duplicates, ",
        num_to_insert,
        " inserted in DB"
      )
    )
  }
  
  ## -----------------------
  ## Build DATA table
  ## -----------------------
  
  # NOTE: The data_to_insert dataframe has the codes for the data to be inserted in both
  # The 'data' table and the 'stats' table.  Don't need to do a compare by pulling
  # the data and stats table from the DB. Just push any LOCAL_data and LOCAL_stats that have a code
  # that is in data_to_insert.
  
  if (num_to_insert == 0) {
    message("**No data to process**")
    
  } else {
    message("Processing DATA_TABLE")
    
    data_processing_start <- Sys.time()
    
    # Get codes for the data to be inserted
    codes_to_insert <- data_to_insert$code
    
    # Make a LOCAL version of the data with a 'code' field
    bridge_table_temp$code <-
      paste(
        bridge_table_temp$alternative_id,
        bridge_table_temp$type_id,
        bridge_table_temp$source_id,
        bridge_table_temp$river_id,
        bridge_table_temp$location_id
      )
    
    LOCAL_data <-
      dplyr::select(bridge_table_temp, id, date, value, code)
    
    # Count how many rows in the local dataset BEFORE removing rows that exist in the DB
    num_df <- length(LOCAL_data$id)
    
    # query the table to see which values exist in the DB compared to my dataframe
    # This gives us the 'data_bridge_ids' that correspond to the 'codes'
    DB_data_bridge <- dbReadTable(connection, "data_bridge")
    
    # MUST do the step below to get the row index for matches, THEN get the corresponding ID for those rows
    data_bridge_index <-
      match(
        LOCAL_data$code,
        DB_data_bridge$code,
        nomatch = NA_integer_,
        incomparables = NULL
      )
    
    # Find the data_bridge_id where LOCAL_data already exists in the DB
    LOCAL_data$data_bridge_id <-
      DB_data_bridge$id[data_bridge_index]
    
    LOCAL_data_to_insert <-
      dplyr::filter(LOCAL_data, LOCAL_data$code %in% codes_to_insert)
    
    DATA_inserted <- LOCAL_data_to_insert
    
    # Process data to add missing columns before inserting into DB
    # Add year, month, day to data table
    LOCAL_data_to_insert$year <-
      lubridate::year(LOCAL_data_to_insert$date)
    LOCAL_data_to_insert$month_num <-
      lubridate::month(LOCAL_data_to_insert$date)
    LOCAL_data_to_insert$day_num <-
      lubridate::day(LOCAL_data_to_insert$date)
    
    
    # ****CHECK THIS - LOOKS LIKE IT RETURNS 365 VALUES?!
    LOCAL_data_to_insert$year_dates_id <-
      DB_year_dates[DB_year_dates$month == LOCAL_data_to_insert$month &&
                      DB_year_dates$day == LOCAL_data_to_insert$day, "id"]
    
    
    modeled_dates_index <-
      match(
        as.character(LOCAL_data_to_insert$date),
        DB_modeled_dates$date,
        nomatch = NA_integer_,
        incomparables = NULL
      )
    
    LOCAL_data_to_insert$date <-
      DB_modeled_dates$id[modeled_dates_index]
    LOCAL_data_to_insert <-
      dplyr::rename(LOCAL_data_to_insert, modeled_dates_id = date)
    
    # Reorder columns
    LOCAL_data_to_insert <-
      LOCAL_data_to_insert[c(
        "id",
        "data_bridge_id",
        "modeled_dates_id",
        "value",
        "year_dates_id",
        "year",
        "month_num",
        "day_num"
      )]
    
    # Convert values to numeric
    options(digits = 9)
    LOCAL_data_to_insert$value <-
      as.numeric(LOCAL_data_to_insert$value)
    
    end_time <- Sys.time()
    elapsed_time <-
      difftime(end_time, data_processing_start, units = "secs")
    
    message(c(
      "It took ",
      round(elapsed_time[[1]], 2),
      " seconds to process the data table for ",
      nrow(LOCAL_data_to_insert),
      " rows of data."
    ))
    
    # Drop the ID column
    LOCAL_data_to_insert_NO_ID <-
      dplyr::select(
        LOCAL_data_to_insert,
        data_bridge_id,
        modeled_dates_id,
        value,
        year_dates_id,
        year,
        month_num,
        day_num
      )
    
    # INSERT into data table
    message(c("Inserting into 'DATA' table..."))
    
    num_to_insert <- length(LOCAL_data_to_insert_NO_ID[[1]])
    num_dups <- num_df - num_to_insert
    
    SQL_start <- Sys.time()
    
    # Write to DB
    RPostgreSQL::dbWriteTable(
      connection,
      "data",
      LOCAL_data_to_insert_NO_ID,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    
    message(c(
      num_df,
      " DATA in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
    
    end_time <- Sys.time()
    elapsed_time <- difftime(end_time, SQL_start, units = "secs")
    
    message(c(
      "SQL insert into 'DATA' complete. Elapsed time: ",
      round(elapsed_time[[1]], 2),
      " seconds. "
    ))
  }
  
  ## -----------------------
  ## CREATE STATS_TABLE
  ## -----------------------
  
  if (num_to_insert == 0) {
    message("**No stats to process**")
    
  } else {
    message("Processing Stats for STATS_TABLE: ")
    start_time <- Sys.time()
    
    stats_data_temp <-
      tidyr::spread(LOCAL_data_to_insert_NO_ID[, c("data_bridge_id", "year_dates_id", "year", "value")], year, value)
    stats_data_temp <-
      cbind(id = 1:nrow(stats_data_temp), stats_data_temp)
    
    stats <- data.frame(
      minimum = numeric(),
      tenth = numeric(),
      fiftieth = numeric(),
      average = numeric(),
      ninetieth = numeric(),
      maximum = numeric()
    )
    
    pb <-
      txtProgressBar(
        min = 1,
        max = nrow(stats_data_temp),
        initial = 1,
        char = "=",
        width = NA,
        "title",
        "label",
        style = 3,
        file = ""
      )
    
    for (i in 1:nrow(stats_data_temp)) {
      setTxtProgressBar(pb, i)
      
      stats[i, c("tenth", "fiftieth", "ninetieth")] <-
        quantile(stats_data_temp[i, 4:ncol(stats_data_temp)], probs = c(0.1, 0.5, 0.9))
      stats[i, "minimum"] <-
        min(stats_data_temp[i, 4:ncol(stats_data_temp)])
      stats[i, "average"] <-
        mean(unlist(stats_data_temp[i, 4:ncol(stats_data_temp)]))
      stats[i, "maximum"] <-
        max(stats_data_temp[i, 4:ncol(stats_data_temp)])
    }
    
    close(pb)
    
    end_time <- Sys.time()
    elapsed_time <- difftime(end_time, start_time, units = "secs")
    
    message(c(
      "It took ",
      round(elapsed_time[[1]], 2),
      " seconds to calculate stats for  ",
      nrow(stats_data_temp),
      " rows of data"
    ))
    
    LOCAL_model_stats <- stats_data_temp[, 1:3]
    LOCAL_model_stats <- cbind(LOCAL_model_stats, stats)
    LOCAL_model_stats_all <- cbind(stats_data_temp, stats)
    
    num_df <- length(LOCAL_model_stats$id)
    
    # MUST remove the ID column before pushing to the DB
    LOCAL_model_stats_NO_ID <-
      dplyr::select(
        LOCAL_model_stats,
        data_bridge_id,
        year_dates_id,
        minimum,
        tenth,
        fiftieth,
        average,
        ninetieth,
        maximum
      )
    
    # STATS_inserted <- to_insert
    STATS_inserted <- LOCAL_model_stats_NO_ID
    
    num_insert <- length(LOCAL_model_stats_NO_ID[[1]])
    num_dups <- num_df - num_insert
    
    # 3 - dbWriteTable to append the new values
    
    message(c("Inserting into 'STATS' table..."))
    
    SQL_start <- Sys.time()
    
    RPostgreSQL::dbWriteTable(
      connection,
      "stats",
      LOCAL_model_stats_NO_ID,
      row.names = FALSE,
      append = TRUE,
      overwrite = FALSE
    )
    
    message(c(
      num_df,
      " STATS in df, ",
      num_dups,
      " duplicates, ",
      num_insert,
      " inserted in DB"
    ))
    
    end_time <- Sys.time()
    elapsed_time <- difftime(end_time, SQL_start, units = "secs")
    
    message(c(
      "SQL insert into 'STATS' complete. Elapsed time: ",
      round(elapsed_time[[1]], 2),
      " seconds. "
    ))
  }
  
  if (save_tables_flag == "yes") {
    message("*** Exporting tables to 'tables_list' for debugging ***")
    
    # Get most recent versions of the DB TABLES
    DB_data_bridge <- dbReadTable(connection, "data_bridge")
    DB_data <- dbReadTable(connection, "data")
    DB_stats <- dbReadTable(connection, "stats")
    
    # --- These might be redundant
    DB_alternatives <- dbReadTable(connection, "alternatives")
    DB_locations <- dbReadTable(connection, "locations")
    DB_rivers <- dbReadTable(connection, "rivers")
    DB_sources <- dbReadTable(connection, "sources")
    DB_types <- dbReadTable(connection, "types")
    DB_modeled_dates <- dbReadTable(connection, "modeled_dates")
    DB_year_dates <- dbReadTable(connection, "year_dates")
    
    tables_list <-
      list(
        "LOCAL_alternatives" = LOCAL_alternatives,
        " LOCAL_sources" = LOCAL_sources,
        "LOCAL_types" = LOCAL_types,
        " LOCAL_rivers" = LOCAL_rivers,
        " LOCAL_locations" = LOCAL_locations,
        "LOCAL_modeled_dates" = LOCAL_modeled_dates,
        " LOCAL_months" = LOCAL_months,
        "LOCAL_year_dates" = LOCAL_year_dates,
        " LOCAL_data_bridge" = LOCAL_data_bridge,
        "LOCAL_data" = LOCAL_data,
        " LOCAL_model_stats" = LOCAL_model_stats,
        "LOCAL_model_stats_all" = LOCAL_model_stats_all,
        "DB_alternatives" = DB_alternatives,
        " DB_sources" = DB_sources,
        "DB_types" = DB_types,
        " DB_rivers" = DB_rivers,
        " DB_locations" = DB_locations,
        "DB_modeled_dates" = DB_modeled_dates,
        " DB_months" = DB_months,
        "DB_year_dates" = DB_year_dates,
        " DB_data_bridge" = DB_data_bridge,
        "DB_data" = DB_data,
        " DB_stats" = DB_stats,
        "ALTS_inserted" = ALTS_inserted,
        "SOURCES_inserted" = SOURCES_inserted,
        "TYPES_inserted" = TYPES_inserted,
        "RIVERS_inserted" = RIVERS_inserted,
        "LOCATIONS_inserted" = LOCATIONS_inserted,
        "MODLED_DATES_inserted" = MODLED_DATES_inserted,
        "MONTHS_inserted" = MONTHS_inserted,
        "YEAR_DATES_inserted" = YEAR_DATES_inserted,
        "DATA_BRIDGE_inserted" = DATA_BRIDGE_inserted,
        "DATA_inserted" = DATA_inserted,
        "STATS_inserted" = STATS_inserted
      )
  } else {
    tables_list <- list()
  }
  
  end_time <- Sys.time()
  elapsed_time <-
    difftime(end_time, SQL_module_start, units = "secs")
  
  message(" ")
  message("-----------------------------")
  message(" *** FINISHED SQL Insert *** ")
  message(c("Elapsed time: ",
            round(elapsed_time[[1]], 2),
            " seconds. "))
  message("-----------------------------")
  message(" ")
  
  dbDisconnect(connection)
  
  return(tables_list)
  
}