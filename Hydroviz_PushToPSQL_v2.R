# Run this following line if testing code without calling the PushToPSQL function
# df <- df_ALL

PushToPSQL <- function(df, DB_selected) {
  ## ---------------------
  # INITIALIZE
  ## ---------------------
  
  message(" ")
  message("-------------------------------------------------------------------------")
  message(
    "IN PushToPSQL. First row of df_final: ",
    df[1,]$alternative,
    " ",
    df[1,]$type,
    " ",
    df[1,]$river,
    " ",
    df[1,]$location
  )
  message("-------------------------------------------------------------------------")
  
  # setwd("~/Box Sync/P722 - MRRIC AM Support/Working Docs/P722 - HydroViz/hydroviz_R_code")
  
  if (!"RPostgreSQL" %in% rownames(installed.packages())) {
    install.packages("RPostgreSQL")
  }
  
  if (!"dotenv" %in% rownames(installed.packages())) {
    install.packages("dotenv")
  }
  
  if (!"DBI" %in% rownames(installed.packages())) {
    install.packages("DBI")
  }
  
  if (!"dbplyr" %in% rownames(installed.packages())) {
    install.packages("dbplyr")
  }
  
  if (!"odbc" %in% rownames(installed.packages())) {
    install.packages("odbc")
  }
  
  library("RPostgreSQL")
  library(DBI)
  library(dplyr)
  library(dbplyr)
  library(odbc)
  library("dotenv")
  
  # # loads the PostgreSQL driver
  driver <- dbDriver("PostgreSQL")
  # driver <- dbDriver("odbc")
  
  
  
  ## ---------------------
  ## CONNECT TO DB
  ## ---------------------
  
  # Load environment variables
  load_dot_env(file = ".env") # Loads variables from .env into R environment
  
  # creates a connection to the postgres database
  if (DB_selected == "Production DB (AWS)") {
    message("**** Inserting into Production DB ****")
    
    # connection <- dbConnect(
    #   driver,
    #   dbname = Sys.getenv("dbnameprod"),
    #   host = Sys.getenv("prodhost"),
    #   port = Sys.getenv("port"),
    #   user = Sys.getenv("user"),
    #   password = Sys.getenv("password")
    # )
    #
    
  } else if (DB_selected == "Testing DB (AWS)") {
    message("**** Inserting into Testing DB ****")
    
    connection <- dbConnect(
      driver,
      dbname = Sys.getenv("dbnametest"),
      host = Sys.getenv("testhost"),
      port = Sys.getenv("port"),
      user = Sys.getenv("user"),
      password = Sys.getenv("password")
    )
  } else if (DB_selected == "Development DB (local)") {
    message("**** Inserting into Development DB (local) ****")
    
    connection <- dbConnect(
      driver,
      dbname = Sys.getenv("dbnamedev"),
      host = Sys.getenv("devhost"),
      port = Sys.getenv("portdev"),
      user = Sys.getenv("userdev"),
      password = Sys.getenv("passworddev")
    )
    
  } else {
    message(" DB NAME NOT RECOGNIZED - STOPPING PushToPSQL")
    return()
  }
  
  ## ---------------------
  
  ## ---------------------
  message(" ")
  message("-------------------------")
  message("*** INSERTING INTO DB ***")
  message("-------------------------")
  message(" ")
  
  ## ---------------------
  # PREP SUMMARY AND BRIDGE DFs
  ## ---------------------
  
  # Start timer
  SQL_module_start <- Sys.time()
  
  # Initialize LOCAL_data_summary and LOCAL_data_bridge
  LOCAL_data_summary <- data.frame(
    alternative = character(),
    type = character(),
    source = character(),
    river = character(),
    location = character(),
    stringsAsFactors = FALSE
  )
  
  LOCAL_data_bridge <- data.frame(
    alt_id = integer(),
    type_id = integer(),
    source_id = integer(),
    river_id = integer(),
    location_id = integer(),
    code = character(),
    dataset_is_new = logical(),
    stringsAsFactors = FALSE
  )
  
  # Initialize flag as FALSE
  LOCAL_data_bridge[1, 'dataset_is_new'] <- FALSE
  
  LOCAL_data_summary[1, "alternative"] <-
    as.character(df$alternative[1])
  LOCAL_data_summary[1, "type"] <- as.character(df$type[1])
  LOCAL_data_summary[1, "source"] <- as.character(df$source[1])
  LOCAL_data_summary[1, "river"] <- as.character(df$river[1])
  LOCAL_data_summary[1, "location"] <- as.character(df$location[1])
  LOCAL_units <- as.character(df$units[1])
  LOCAL_measure <- as.character(df$measure[1])
  
  # message("LOCAL_data_summary: ", paste(LOCAL_data_summary[1, 1], LOCAL_data_summary[1, 2], LOCAL_data_summary[1, 3], LOCAL_data_summary[1, 4], LOCAL_data_summary[1, 5]))
  
  ## --------------------------
  ## 1. Check ALTERNATIVE in DB
  ## --------------------------
  
  # Does the alternative exist in the DB?
  DB_alternative <-
    dbGetQuery(
      connection,
      paste0(
        "SELECT id, alternative FROM alternatives WHERE alternative = '",
        LOCAL_data_summary[1, "alternative"] ,
        "'"
      )
    )
  
  if (nrow(DB_alternative) == 0) {
    # If the alternative is NOT in the DB, then insert it and get the new id
    LOCAL_data_bridge[1, 'dataset_is_new'] <- TRUE
    
    returned_id <-
      dbGetQuery(
        connection,
        paste0(
          "INSERT INTO alternatives (alternative) VALUES ('",
          LOCAL_data_summary[1, "alternative"],
          "') RETURNING id, alternative;"
        )
      )
    
    message("Inserted ALTERNATIVE into DB: ",
            paste(returned_id[1, 1], "-", returned_id[1, 2]))
    
    # Add the id to LOCAL_data_bridge
    LOCAL_data_bridge[1, "alt_id"] <- returned_id$id
    
  } else {
    # Add the id from the SELECT query to LOCAL_data_bridge
    LOCAL_data_bridge[1, "alt_id"] <- DB_alternative$id
    message("ALTERNATIVE already in DB")
  }
  
  
  
  ## -----------------------
  ## 2. Check TYPE in DB
  ## -----------------------
  
  # Does the type exist in the DB?
  DB_type <-
    dbGetQuery(
      connection,
      # paste0(
      #   "SELECT id, type FROM types WHERE type = '",
      #   LOCAL_data_summary[1, "type"] ,
      #   "'"
      # )
      paste0(
        "SELECT * FROM types WHERE type = '",
        LOCAL_data_summary[1, "type"] ,
        "' AND units = '",
        LOCAL_units,
        "' AND measure= '",
        LOCAL_measure,
        "'"
      )
    )
  
  if (nrow(DB_type) == 0) {
    # If the type is NOT in the DB, then insert it and get the new id
    LOCAL_data_bridge[1, 'dataset_is_new'] <- TRUE
    
    returned_id <-
      dbGetQuery(
        connection,
        # paste0(
        #   "INSERT INTO types (type) VALUES ('",
        #   LOCAL_data_summary[1, "type"],
        #   "') RETURNING id, type;"
        # )
        paste0(
          "INSERT INTO types (type, units, measure) VALUES ('",
          toupper(LOCAL_data_summary[1, "type"]),
          "', '",
          toupper(LOCAL_units),
          "','",
          toupper(LOCAL_measure),
          "') RETURNING *;"
        )
      )
    
    message("Inserted TYPE into DB: ",
            paste(returned_id[1, 1], "-", returned_id[1, 2]))
    
    # Add the id to LOCAL_data_bridge
    LOCAL_data_bridge[1, "type_id"] <- returned_id$id
    
  } else {
    # Add the id from the SELECT query to LOCAL_data_bridge
    LOCAL_data_bridge[1, "type_id"] <- DB_type$id
    message("TYPE already in DB")
  }
  
  
  
  ## -----------------------
  ## 3. Check SOURCE in DB
  ## -----------------------
  
  # Does the source exist in the DB?
  DB_source <-
    dbGetQuery(
      connection,
      paste0(
        "SELECT id, source FROM sources WHERE source = '",
        LOCAL_data_summary[1, "source"] ,
        "'"
      )
    )
  
  if (nrow(DB_source) == 0) {
    # If the source is NOT in the DB, then insert it and get the new id
    LOCAL_data_bridge[1, 'dataset_is_new'] <- TRUE
    
    returned_id <-
      dbGetQuery(
        connection,
        paste0(
          "INSERT INTO sources (source) VALUES ('",
          LOCAL_data_summary[1, "source"],
          "') RETURNING id, source;"
        )
      )
    
    message("Inserted SOURCE into DB: ",
            paste(returned_id[1, 1], "-", returned_id[1, 2]))
    
    # Add the id to LOCAL_data_bridge
    LOCAL_data_bridge[1, "source_id"] <- returned_id$id
    
  } else {
    # Add the id from the SELECT query to LOCAL_data_bridge
    LOCAL_data_bridge[1, "source_id"] <- DB_source$id
    message("SOURCE already in DB")
  }
  
  
  ## -----------------------
  ## 4. Check RIVER in DB
  ## -----------------------
  
  # Does the river exist in the DB?
  DB_river <-
    dbGetQuery(
      connection,
      paste0(
        "SELECT id, river FROM rivers WHERE river = '",
        LOCAL_data_summary[1, "river"] ,
        "'"
      )
    )
  
  if (nrow(DB_river) == 0) {
    # If the river is NOT in the DB, then insert it and get the new id
    LOCAL_data_bridge[1, 'dataset_is_new'] <- TRUE
    
    returned_id <-
      dbGetQuery(
        connection,
        paste0(
          "INSERT INTO rivers (river) VALUES ('",
          LOCAL_data_summary[1, "river"],
          "') RETURNING id, river;"
        )
      )
    
    message("Inserted RIVER into DB: ",
            paste(returned_id[1, 1], "-", returned_id[1, 2]))
    
    # Add the id to LOCAL_data_bridge
    LOCAL_data_bridge[1, "river_id"] <- returned_id$id
    
  } else {
    # Add the id from the SELECT query to LOCAL_data_bridge
    LOCAL_data_bridge[1, "river_id"] <- DB_river$id
    message("RIVER already in DB")
    
  }
  
  
  ## -----------------------
  ## 5. Check LOCATION in DB
  ## -----------------------
  
  # Does the location exist in the DB?
  DB_location <-
    dbGetQuery(
      connection,
      paste0(
        "SELECT id, location FROM locations WHERE location = '",
        LOCAL_data_summary[1, "location"] ,
        "'"
      )
    )
  
  if (nrow(DB_location) == 0) {
    # If the location is NOT in the DB, then insert it and get the new id
    LOCAL_data_bridge[1, 'dataset_is_new'] <- TRUE
    
    returned_id <-
      dbGetQuery(
        connection,
        paste0(
          "INSERT INTO locations (location) VALUES ('",
          LOCAL_data_summary[1, "location"],
          "') RETURNING id, location;"
        )
      )
    
    message("Inserted LOCATION into DB: ",
            paste(returned_id[1, 1], "-", returned_id[1, 2]))
    
    # Add the id to LOCAL_data_bridge
    LOCAL_data_bridge[1, "location_id"] <- returned_id$id
    
  } else {
    # Add the id from the SELECT query to LOCAL_data_bridge
    LOCAL_data_bridge[1, "location_id"] <- DB_location$id
    message("LOCATION already in DB")
    
  }
  
  
  ## -----------------------
  ## 6. Calculate data_bridge code
  ## -----------------------
  
  LOCAL_data_bridge[1, "code"] <-
    paste(
      LOCAL_data_bridge[1, 1],
      LOCAL_data_bridge[1, 2],
      LOCAL_data_bridge[1, 3],
      LOCAL_data_bridge[1, 4],
      LOCAL_data_bridge[1, 5]
    )
  
  message("LOCAL_data_bridge: ", LOCAL_data_bridge[1, 6])

  
  # -----------------
  # Each element of the data bridge may be in the DB, but not in the combination presented
  # by the data set - check if the data_bridge_id exists in the DB, then decide what to do
  # -----------------
  
  
  data_bridge_id <-
    dbGetQuery(
      connection,
      paste0(
        "SELECT id FROM data_bridge WHERE code = '",
        LOCAL_data_bridge[1, "code"],
        "'"
      )
    )
  
  if (nrow(data_bridge_id) == 0) {
    # If the location is NOT in the DB, then insert it and get the new id
    LOCAL_data_bridge[1, 'dataset_is_new'] <- TRUE
  }
  
  ## -----------------------
  ## IF DATASET IS NEW - PROCESS AND INSERT INTO DB
  ## -----------------------
  
  if (LOCAL_data_bridge[1, 'dataset_is_new'] == FALSE) {
    # If all of the fields are already in the DB, then skip processing of data, don't insert, send message that it is already in there
    
    message('Dataset already exists in the DB - Nothing inserted')
    
    data_bridge_id <-
      dbGetQuery(
        connection,
        paste0(
          "SELECT id FROM data_bridge WHERE code = '",
          LOCAL_data_bridge[1, "code"],
          "'"
        )
      )
    
    LOCAL_data_bridge[1, "data_bridge_id"] <- data_bridge_id
    
  } else {
    # CONTINUE PROCESSING DATA TO INSERT INTO THE DB
    
    # -----------------------
    # Insert data_bridge into DB
    # -----------------------
    
    returned_id <-
      dbGetQuery(
        connection,
        paste0(
          "INSERT INTO data_bridge (alternative_id, type_id, source_id, river_id, location_id, code) VALUES (",
          paste(
            LOCAL_data_bridge[1, 1],
            LOCAL_data_bridge[1, 2],
            LOCAL_data_bridge[1, 3],
            LOCAL_data_bridge[1, 4],
            LOCAL_data_bridge[1, 5],
            sep = ","
          ),
          ", '",
          LOCAL_data_bridge[1, 6],
          "'",
          ") RETURNING id;"
        )
      )
    
    message(
      "Inserted DATA_BRIDGE into DB: id - ",
      paste(returned_id[1, 1], ", CODE -", LOCAL_data_bridge[1, 6])
    )
    
    LOCAL_data_bridge[1, "data_bridge_id"] <- returned_id[1, 1]
    
    
    ## -----------------------
    ## Build MONTHS table & INSERT INTO DB
    ## -----------------------
    
    # Check if the 'months' table exists. If it does, skip this step.
    DB_months_count <-
      dbGetQuery(connection, "SELECT COUNT(month_name) FROM months")
    
    
    if ((DB_months_count < 12) && (DB_months_count > 0)) {
      message("Possible DB error - less than 12 months in the 'months' table")
      
    } else if (DB_months_count == 0) {
      # INSERT INTO DB
      # Assuming that the current dataset has all 12 months, so don't need to verify that it does, just insert it
      
      # Get data from the df
      distinctDates <- data.frame(dplyr::distinct(df, date))
      LOCAL_months <-
        data.frame(month_name = unique(months(distinctDates$date)))
      
      LOCAL_months_list <- as.character(LOCAL_months$month)
      # LOCAL_months_list <-
      #   paste0('\'', paste(LOCAL_months_list, collapse = '\',\''), '\'')
      #
      LOCAL_months_list <-
        paste0('(\'',
               paste(LOCAL_months_list, collapse = '\'),(\''),
               '\')')
      
      Months_df <-
        dbGetQuery(
          connection,
          paste0(
            "INSERT INTO months (month_name) VALUES ",
            LOCAL_months_list,
            " RETURNING *;"
          )
        )
      
      message("Month names inserted into DB in 'months' table")
      
    } else {
      message("Months table already in DB - nothing added")
      
      Months_df <-
        dbGetQuery(connection, "SELECT * FROM months")
      
    }
    
    
    
    ## -----------------------
    ## Build MODELED_DATES table & INSERT INTO DB
    ## -----------------------
    
    # Check if the 'modeled_dates' table exists and has 29930 entries. If it does, skip this step.
    
    DB_modeled_dates_count <-
      dbGetQuery(connection,
                 "SELECT COUNT(DISTINCT date) FROM modeled_dates")
    
    if ((DB_modeled_dates_count < 29930) &&
        (DB_modeled_dates_count > 0)) {
      message("Possible DB error - less than 29930 modeled_dates in the 'modeled_dates' table")
      
    } else if (DB_modeled_dates_count == 0) {
      # INSERT INTO DB
      # Get data from the df
      # Assuming that the current dataset has all 29930 modeled_dates, so don't need to verify that it does, just insert it
      
      LOCAL_modeled_dates <- data.frame(dplyr::distinct(df, date))
      
      LOCAL_modeled_dates$year <-
        lubridate::year(LOCAL_modeled_dates$date)
      LOCAL_modeled_dates$month <-
        lubridate::month(LOCAL_modeled_dates$date)
      LOCAL_modeled_dates$day <-
        lubridate::day(LOCAL_modeled_dates$date)
      #
      # LOCAL_modeled_dates_list <-
      #   as.character(LOCAL_modeled_dates$date)
      #
      # LOCAL_modeled_dates_list <-
      #   paste0('\'',
      #          paste(LOCAL_modeled_dates_list, collapse = '\',\''),
      #          '\'')
      
      to_insert <-
        paste0(
          "(",
          paste0(
            "'",
            LOCAL_modeled_dates$date,
            "','",
            LOCAL_modeled_dates$year,
            "','",
            LOCAL_modeled_dates$month,
            "','",
            LOCAL_modeled_dates$day,
            "'",
            collapse = "),("
          ),
          ")"
        )
      
      Modeled_dates_df <-
        dbGetQuery(
          connection,
          paste0(
            "INSERT INTO modeled_dates (date, year, month, day) VALUES ",
            to_insert,
            " RETURNING *;"
          )
        )
      
      message("Modeled_dates inserted into DB in 'modeled_dates' table")
      
    } else {
      message("Modeled_dates table already in DB - nothing added")
      
      Modeled_dates_df <-
        dbGetQuery(connection,
                   "SELECT * FROM modeled_dates")
    }
    
    
    ## -----------------------
    ## Build YEAR_DATES table & INSERT INTO DB
    ## -----------------------
    
    # Check if the 'year_dates' table exists and has 365 entries. If it does, skip this step.
    
    DB_year_dates_count <-
      dbGetQuery(connection, "SELECT COUNT(DISTINCT id) FROM year_dates")
    
    if ((DB_year_dates_count < 365) && (DB_year_dates_count > 0)) {
      message("Possible DB error - less than 365 year_dates in the 'year_dates' table")
      
    } else if (DB_year_dates_count == 0) {
      # INSERT INTO DB
      # Assuming that the current dataset has all 365 year_dates, so don't need to verify that it does, just insert it
      
      # Prep one year of dates to insert in DB
      one_year <- df[lubridate::year(df$date) == 1931, ]$date
      LOCAL_year_dates <- data.frame(id = 1:365)
      LOCAL_year_dates$month_name <- months(unique(one_year))
      LOCAL_year_dates$month <-
        as.integer(format(unique(one_year), "%m"))
      LOCAL_year_dates$day <- lubridate::day(unique(one_year))
      
      to_insert <- LOCAL_year_dates[, 2:4]
      
      to_insert <-
        paste0(
          "(",
          paste0(
            "'",
            LOCAL_year_dates$month_name,
            "','",
            LOCAL_year_dates$month,
            "','",
            LOCAL_year_dates$day,
            "'",
            collapse = "),("
          ),
          ")"
        )
      
      # INSERT INTO DB AND RETURN IDS
      Year_dates_df <-
        dbGetQuery(
          connection,
          paste0(
            "INSERT INTO year_dates (month_name, month, day) VALUES ",
            to_insert,
            " RETURNING *;"
          )
        )
      
      message("Year_dates inserted into DB in 'modeled_dates' table")
      
    } else {
      message("year_dates table already in DB - nothing added")
      
      # QUERY DB TO GET IDS
      Year_dates_df <-
        dbGetQuery(connection,
                   "SELECT * FROM year_dates")
    }
    
    
    ## -----------------------
    ## Build DATA table & INSERT INTO DB
    ## -----------------------
    
    # NOTE: The data_to_insert dataframe has the codes for the data to be inserted in both
    # The 'data' table and the 'stats' table.  Don't need to do a compare by pulling
    # the data and stats table from the DB. Just push any LOCAL_data and LOCAL_stats that have a code
    # that is in data_to_insert.
    
    message("Processing DATA_TABLE")
    
    data_processing_start <- Sys.time()
    
    # data_temp  <- data.frame(
    #   data_bridge_id = integer(),
    #   date = character(),
    #   modeled_dates_id = integer(),
    #   value = integer(),
    #   year_dates_id = integer(),
    #   year = integer(),
    #   month_num = integer(),
    #   day_num = integer(),
    #   stats_id = integer(),
    #   stringsAsFactors = FALSE
    # )
    
    
    data_temp <- data.frame(data_bridge_id = LOCAL_data_bridge[1, "data_bridge_id"],
                            date = df[, 'date'],
                            value = df[, 'value'])
    
    # Process data to add missing columns before inserting into DB
    # Add year, month, day to data table
    data_temp$year <-
      lubridate::year(data_temp$date)
    data_temp$month_num <-
      lubridate::month(data_temp$date)
    data_temp$day_num <-
      lubridate::day(data_temp$date)
    
    # Get id from Year_dates_df where month_num = month, and day_num = day. Add as column to data_temp
    # JOIN the tables
    data_temp <-
      left_join(data_temp,
                Year_dates_df[, c("id", "month", "day")],
                by = c("month_num" = "month", "day_num" = "day"))
    data_temp$date <- as.character(data_temp$date)
    
    # Now, delete the month name column and rename 'id' to 'year_dates_id'
    # names(data_temp)[names(data_temp) == 'id'] <- 'year_dates_id'
    data_temp <-
      dplyr::rename(data_temp, year_dates_id = id)
    
    # Repeat this to get 'modeled_dates'
    data_temp <-
      left_join(data_temp, Modeled_dates_df[, c("id", "date")], by = c("date" = "date"))
    # names(data_temp)[names(data_temp) == 'id'] <- 'modeled_dates_id'
    data_temp <-
      dplyr::rename(data_temp, modeled_dates_id = id)
    
    # Remove 'date' column
    data_temp <- subset(data_temp, select = -date)
    
    # Reorder columns
    data_temp <-
      data_temp[c(
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
    
    data_temp$value <-
      as.character(data_temp$value)
    
    data_temp$value <-
      as.numeric(data_temp$value)
    
    # The conversion to as.numeric will coerce "NULL" into "NA", but we need these to be "NaN"
    # to insert into Postgres for numeric types
    data_temp$value[is.na(data_temp$value)] <- NaN

    
    end_time <- Sys.time()
    elapsed_time <-
      difftime(end_time, data_processing_start, units = "secs")
    
    message(c(
      "It took ",
      round(elapsed_time[[1]], 2),
      " seconds to process the data table for ",
      nrow(data_temp),
      " rows of data."
    ))
    
    
    # INSERT into data table
    message(c("Inserting into 'DATA' table..."))
    
    # num_to_insert <- length(data_temp[[1]])
    # num_dups <- num_df - num_to_insert
    
    SQL_start <- Sys.time()
    
    to_insert <-
      paste0(
        "(",
        paste0(
          "'",
          data_temp$data_bridge_id,
          "','",
          data_temp$modeled_dates_id,
          "','",
          data_temp$value,
          "','",
          data_temp$year_dates_id,
          "','",
          data_temp$year,
          "','",
          data_temp$month_num,
          "','",
          data_temp$day_num,
          "'",
          collapse = "),("
        ),
        ")"
      )
    
    
    # INSERT INTO DB AND RETURN IDS
    returned_data_ids <-
      dbGetQuery(
        connection,
        paste0(
          "INSERT INTO data (data_bridge_id, modeled_dates_id, value, year_dates_id, year, month_num, day_num) VALUES ",
          to_insert,
          " RETURNING id;"
        )
      )
    
    end_time <- Sys.time()
    elapsed_time <- difftime(end_time, SQL_start, units = "secs")
    
    message(c(
      "SQL insert into 'DATA' complete. Elapsed time: ",
      round(elapsed_time[[1]], 2),
      " seconds. "
    ))
    
    
    

    # Calculate the STATS, push to the DB, get the 'id',
    # then merge in the ID column and push data_temp to the DB

    ## -----------------------
    ## CREATE STATS_TABLE
    ## -----------------------

    message("Processing Stats for STATS_TABLE: ")
    start_time <- Sys.time()

    stats_data_temp <-
      tidyr::spread(data_temp[, c("data_bridge_id", "year_dates_id", "year", "value")], year, value)
    stats_data_temp <-
      cbind(id = 1:nrow(stats_data_temp), stats_data_temp)

    # stats_data_temp <- data.frame(stats_data_temp)
    
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

    # Convert all NaNs to NAs for stats calculations
    for (r in 4:length(colnames(stats_data_temp))) {
      stats_data_temp[is.nan(stats_data_temp[,r]), r] <- NA
    }

    
    for (i in 1:nrow(stats_data_temp)) {
      setTxtProgressBar(pb, i)

      stats[i, c("tenth", "fiftieth", "ninetieth")] <-
        quantile(stats_data_temp[i, 4:ncol(stats_data_temp)], probs = c(0.1, 0.5, 0.9), na.rm=TRUE)
      stats[i, "minimum"] <-
        min(stats_data_temp[i, 4:ncol(stats_data_temp)], na.rm=TRUE)
      stats[i, "average"] <-
        mean(unlist(stats_data_temp[i, 4:ncol(stats_data_temp)]),na.rm=TRUE)
      stats[i, "maximum"] <-
        max(stats_data_temp[i, 4:ncol(stats_data_temp)], na.rm=TRUE)
    }

    # Convert NA and Inf / -Inf to NaN to insert into DB
    stats[is.na(stats)] <- NaN
    stats[stats == Inf] <- NaN
    stats[stats == -Inf] <- NaN
    
    
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



    # STOPPED HERE **********
    # STOPPED HERE **********
    # STOPPED HERE **********





    ## -----------------------
    ## INSERT STATS INTO DB
    ## -----------------------

    LOCAL_model_stats <- stats_data_temp[, 1:3]
    LOCAL_model_stats <- cbind(LOCAL_model_stats, stats)

    # # ** OPTIONAL ** -- Write the table to a .csv file
      # # Will create a table with all of the years in columns and stats in columns too
      #
      # LOCAL_model_stats_all <- cbind(stats_data_temp, stats)
      # stats_file_path <- "/Users/christianbeaudrie/Box Sync/P722 - MRRIC AM Support/Working Docs/P722 - HydroViz/hydroviz_R_code"
      # stats_file_name <- "data_and_stats_table.csv"
        # Need to programatically change the stats_file_name for each loop so you won't write
        # over the existing .csv file each time this is run.
      #
      # path_and_filename<- paste0(stats_file_path, "/", stats_file_name)
      # write.csv(LOCAL_model_stats_all,path_and_filename, row.names = FALSE)

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

    to_insert <-
      paste0(
        "(",
        paste0(
          "'",
          LOCAL_model_stats_NO_ID$data_bridge_id,
          "','",
          LOCAL_model_stats_NO_ID$year_dates_id,
          "','",
          LOCAL_model_stats_NO_ID$minimum,
          "','",
          LOCAL_model_stats_NO_ID$tenth,
          "','",
          LOCAL_model_stats_NO_ID$fiftieth,
          "','",
          LOCAL_model_stats_NO_ID$average,
          "','",
          LOCAL_model_stats_NO_ID$ninetieth,
          "','",
          LOCAL_model_stats_NO_ID$maximum,
          "'",
          collapse = "),("
        ),
        ")"
      )


    # INSERT INTO DB AND RETURN IDS
    returned_stats_ids <-
      dbGetQuery(
        connection,
        paste0(
          "INSERT INTO stats (data_bridge_id, year_dates_id, minimum, tenth, fiftieth, average, ninetieth, maximum) VALUES ",
          to_insert,
          " RETURNING id;"
        )
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


    # END OF LOOP TRIGGERED IF data_bridge ISN'T IN THE DB
  }
  
  dbDisconnect(connection)
  
  return()
  
}
