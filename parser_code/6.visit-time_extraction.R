library(stringr)
library(janitor)
courses_path = "/home/vovan/Desktop/september_2020/"
course_name <- "vvedenie-mashinnoe-obuchenie"

##########################################

names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
visits_path = "/home/vovan/Desktop/visits/"
courses_path = "/home/vovan/Desktop/september_2020/"


visits_time_extraction <- function(name){
  path_to_files = paste("/home/vovan/Desktop/down/",  name, sep = "")
  path_to_where_save = paste("/home/vovan/Desktop/pre_visit_ts/",  name, "/", sep = "")
  final_path = "/home/vovan/Desktop/visit_ts/"
  dir.create("/home/vovan/Desktop/pre_visit_ts/", showWarnings = FALSE)
  dir.create(path_to_where_save, showWarnings = FALSE)
  dir.create(final_path, showWarnings = FALSE)
  down_list <- list.files(path = path_to_files, pattern = "*.csv.gz", full.names = T)
  pre_list <- list.files(path = str_sub(path_to_where_save, end = -2), full.names = T)
  compare_list <- list.files(path = paste("/home/vovan/Desktop/pre_accesses/", name,  "/", sep = ""), full.names = T)
  if (length(pre_list) != length(compare_list))
  {
    for (file_name_in_down in down_list){
      if (file.size(file_name_in_down) > 4000)
      {
        if (grepl("access", file_name_in_down) == TRUE)
        {
          file_name_in_pre <- paste(path_to_where_save, 
                                    str_sub(file_name_in_down, start = nchar(path_to_files)+2, end =-8), '.csv',sep='')
          if (!(file_name_in_pre %in% pre_list)) {
            df_unparsed_json_value <- read_delim(paste(file_name_in_down,sep=''), ",",
                                                 col_names = c("user_id", "hashed_session_cookie_id",
                                                               "server_timestamp", "hashed_ip", "user_agent",
                                                               "url", "initial_referrer_url", "browser_language",
                                                               "course_id", "country_cd", "region_cd", "timezone",
                                                               "os", "browser", "key", "value"),
                                                 escape_double = FALSE, escape_backslash = TRUE)
            df_unparsed_json_value <- df_unparsed_json_value %>% dplyr::select(user_id, url, course_id, server_timestamp)
            write.csv(df_unparsed_json_value, file=paste(path_to_where_save, 
                                                         str_sub(file_name_in_down, start = nchar(path_to_files)+2, end =-8),
                                                         '.csv',sep=''))
            pre_list <- list.files(path = str_sub(path_to_where_save, end = -2), full.names = T)
          }
        }
      }
    }
    q <- list.files(path = path_to_where_save, full.names = TRUE)
    q1 <- lapply(q, fread)
    access <- data.table::rbindlist(q1, fill=TRUE) %>% dplyr::select(-V1) %>% row_to_names(row_number = 1) %>% 
      filter(grepl("discussion", url )) %>% filter(!grepl("discussionPrompt", url ))
    write.csv(access, file=paste(final_path,  name, ".csv", sep = ""), row.names = FALSE)
    rm(q)
    rm(q1)
    rm(access)
  }
}

# 2. Применяем функцию access_extraction только к тем курсам где, скачались все файлы 
preaccess = "/home/vovan/Desktop/pre_accesses/"

for (i in 1:99) {
  if (names$ready[i] == "done"){
    name = names$course_slug[i]
    visits_time_extraction(name)
  }
  i = i + 1 
  print (i)
}
