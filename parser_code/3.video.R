
videofile_extraction <- function(name){
  dir.create("/home/vovan/Desktop/pre_video/", showWarnings = FALSE)
  names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
  path_to_down = paste("/home/vovan/Desktop/down/",  name, sep = "")
  path_to_pre = paste("/home/vovan/Desktop/pre_video/",  name, "/", sep = "")
  path_to_video = "/home/vovan/Desktop/video/"
  dir.create(path_to_pre, showWarnings = FALSE)
  down_list <- list.files(path = path_to_down, pattern = "*.csv.gz", full.names = T)
  pre_list <- list.files(path = str_sub(path_to_pre, end = -2), full.names = T)
  for (file_name_in_down in down_list) {
    if (file.size(file_name_in_down) > 4000) {
      if (grepl("video", file_name_in_down) == TRUE) {
        file_name_in_pre <- paste(path_to_pre, 
                                  str_sub(file_name_in_down, start = nchar(path_to_down)+2, end =-8), '.csv',sep='')
        if (!(file_name_in_pre %in% pre_list)) {

            df_unparsed_json_value <- read_delim(paste(file_name_in_down,sep=''), ",",
                                                       col_names = c("user_id", "hashed_session_cookie_id",
                                                                     "server_timestamp", "hashed_ip", "user_agent",
                                                                     "url", "initial_referrer_url", "browser_language",
                                                                     "course_id", "country_cd", "region_cd", "timezone",
                                                                     "os", "browser", "key", "value"),
                                                       escape_double = FALSE, escape_backslash = TRUE) %>% 
              filter(key == "end") %>% # берем только видео что были досмотрены до конца
              dplyr::select(user_id, url, course_id) 
            write.csv(df_unparsed_json_value, file= file_name_in_pre)
            pre_list <- list.files(path = str_sub(path_to_pre, end = -2), full.names = T)
       }
      }
    }
  }
  pre_list <- list.files(path = path_to_pre, full.names = T)
  pre_list1 <- lapply(pre_list, fread)
  dir.create(path_to_video, showWarnings = FALSE)
  video <- data.table::rbindlist(pre_list1, fill=TRUE) %>% dplyr::select(-V1) %>% row_to_names(row_number = 1) %>% 
    filter(!is.na(url))
  write.csv(video, file=paste(path_to_video,  name, ".csv", sep = ""), row.names = FALSE)
}


watch_path = "/home/vovan/Desktop/watch/"

watch_extraction <- function(){
  dir.create(watch_path, showWarnings = FALSE)
  video_lists <- list.files(path = "/home/vovan/Desktop/video", pattern = "*.csv", full.names = T)
  for (list in video_lists) {
    video <- fread(list, header = TRUE)
    watch <- video %>% rename(hse_user_id = user_id) %>% 
      group_by(course_id, hse_user_id) %>% 
      # only video watched till the end
      # watch_all - number of video watched till the end, watch_unique - number of unique video watched till the end
      summarise(watch_all = n(), watch_unique = n_distinct(url))
    write.csv(watch, file=paste(watch_path,  str_sub(list, start = nchar(watch_path)+1),sep=''), row.names = FALSE)
  }
}
watch_extraction()
