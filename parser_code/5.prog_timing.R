library(stringr)
library(janitor)
names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
pre_visits_path = "/home/vovan/Desktop/pre_visit_ts/"
final_path <- "/home/vovan/Desktop/prog_visit_ts/"

for (i in 1:99) {
  if (names$ready[i] == "done" && i != 6){
    name = names$course_slug[i]
    prog_time_extraction(name)
  }
  i = i + 1 
  print (i)
}

name <- "algorithms-on-graphs"

prog_time_extraction <- function(name){
    dir.create(final_path, showWarnings = FALSE)
    pre_visits_path2 = paste(pre_visits_path,  name, "/", sep = "")
    ready <- list.files(path = str_sub(final_path, end = -2), full.names = TRUE)
    file_name <- paste(str_sub(final_path, end = -2), "/", name, '.csv',sep='')
    if (!(file_name %in% ready)) 
    {
      q <- list.files(path = pre_visits_path2, full.names = TRUE) %>% lapply(., fread)
      if (length(q) != 0)
      {
        access <- data.table::rbindlist(q, fill=TRUE) %>% dplyr::select(-V1) %>% row_to_names(row_number = 1) %>% 
          rename(hse_user_id = user_id) %>% 
          filter(grepl("programming", url)) %>% filter(!grepl("supplement", url)) %>% 
          filter(!grepl("discussion", url)) %>% 
          mutate(course_item_id = str_extract(url, ("(?<=programming/).*?(?=/)")), 
                 submission_b = grepl("submission", url))
        if(nrow(access) != 0)
        {
          access1 <- access %>% group_by(hse_user_id, course_item_id)  %>%
            filter(any(submission_b == TRUE)) %>% 
            dplyr::select(-url, -course_id) %>% 
            group_by(hse_user_id, course_item_id) %>%  arrange(server_timestamp, .by_group = TRUE) %>%
            summarise(first_interaction = min(server_timestamp)) %>% filter(!is.na(course_item_id))
          write.csv(access1, file=paste(final_path,  name, ".csv", sep = ""), row.names = FALSE)
        }
        rm(access)
        rm(access1)
        rm(q)
    }
    }
}
