#install.packages("janitor")
library(dplyr)
library(data.table)
library(readr)
library(stringr)
library(data.table)
library(janitor)

# 1. 
# Из папки down (downloaded) в папку pre_accesses, а затем в accesses
# вытаскиваем таблицу из архива
# выбрасываем пустые файлы
# из таблицы берем только три важные нам колонки: user_id, url, course_id
# Делаем все эти действия в рамках функции access_extraction
# В папке pre_accesss - каждому дню соотвествует одна таблица, в access - все дни аггрегировану в одну общую таблицу

names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")

access_extraction <- function(name){
  path_to_down = paste("/home/vovan/Desktop/down/",  name, sep = "")
  path_to_pre = paste("/home/vovan/Desktop/pre_accesses/",  name, "/", sep = "")
  path_to_access = "/home/vovan/Desktop/accesses/"
  
  dir.create(path_to_pre, showWarnings = FALSE)
  down_list <- list.files(path = path_to_down, pattern = "*.csv.gz", full.names = T)
  pre_list <- list.files(path = str_sub(path_to_pre, end = -2), full.names = T)
  
  for (file_name_in_down in down_list) {
    if (file.size(file_name_in_down) > 4000) {
      if (grepl("access", file_name_in_down) == TRUE) {
        file_name_in_pre <- paste(path_to_pre, 
                                  str_sub(file_name_in_down, start = nchar(path_to_down)+2, end =-8), '.csv',sep='')
        if (!(file_name_in_pre %in% pre_list)) {
          df_unparsed_json_value <- read_delim(paste(file_name_in_down,sep=''), ",",
                                               col_names = c("user_id", "hashed_session_cookie_id",
                                                             "server_timestamp", "hashed_ip", "user_agent",
                                                             "url", "initial_referrer_url", "browser_language",
                                                             "course_id", "country_cd", "region_cd", "timezone",
                                                             "os", "browser", "key", "value"),
                                               escape_double = FALSE, escape_backslash = TRUE)
          df_unparsed_json_value <- df_unparsed_json_value %>% dplyr::select(user_id, url, course_id)
          write.csv(df_unparsed_json_value, file= file_name_in_pre)
          pre_list <- list.files(path = str_sub(path_to_pre, end = -2), full.names = T)
        }
      }
    }
  }
  q <- list.files(path = path_to_pre, full.names = TRUE)
  q1 <- lapply(q, fread)
  access <- data.table::rbindlist(q1, fill=TRUE) %>% dplyr::select(-V1) %>% row_to_names(row_number = 1)
  write.csv(access, file=paste(path_to_access,  name, ".csv", sep = ""), row.names = FALSE)

}

# 2. Применяем функцию access_extraction только к тем курсам где, скачались все файлы 
preaccess = "/home/vovan/Desktop/pre_accesses/"
source("R_code/3.video.R")
for (i in 1:99) {
  if (names$ready[i] == "done"){
    name = names$course_slug[i]
    access_extraction(name)
    #videofile_extraction(name)
  }
  i = i + 1 
  print (i)
}
