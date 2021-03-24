library(dplyr)
library(data.table)
library(readr)
library(stringr)
library(data.table)
library(janitor)
library(glmer)
library(lme4)
library(sjPlot)
library(broom)
library(tidyr)


names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
visits_path = "/home/vovan/Desktop/visits/"
courses_path = "/home/vovan/Desktop/september_2020/"
watch_path = "/home/vovan/Desktop/watch/"

#1. 
# Из папки accesses в папку visits
# Посчитать количество посещений форума

# extract visits from the access
visits_extraction <- function(){
  access_lists <- list.files(path = "/home/vovan/Desktop/accesses", pattern = "*.csv", full.names = T)
  for (list in access_lists) {
    access <- fread(list, header = TRUE)
    a1 <- access %>% rename(hse_user_id = user_id) %>% 
      filter(grepl("discussion", url )) %>% filter(!grepl("discussionPrompt", url )) %>% group_by(course_id, hse_user_id) %>% 
      summarise(n = n())
    write.csv(a1, file=paste(visits_path,  str_sub(list, start = nchar(visits_path)+3),sep=''), row.names = FALSE)
  }
}
visits_extraction()

# extract watches from the video

#2. 
# Объединяем количество посещений с данными об оценках и слаге курса
# Удалим персонал курсов и тех, кто не закончил курс
# Сделаем два вида переменных visit: бинарную и пуассовновскую

is_item_prog <-function(course_name)
{
  course_item_types <- fread(paste0(courses_path, '/', course_name, '/', 'course_item_types.csv')) %>% 
    filter(!is.na(atom_content_type_id))
  course_items <- fread(paste0(courses_path, '/', course_name, '/', 'course_items.csv')) %>% dplyr::select(course_id, course_item_type_id) %>% 
    group_by(course_id, course_item_type_id) %>% summarise(n = n())
  course_items$course_item_type_category <- 0
  for (i in 1:nrow(course_items)) {
    for (j in 1:nrow(course_item_types)){
      if (course_items$course_item_type_id[i] == course_item_types$course_item_type_id[j]) {
        course_items$course_item_type_category[i] = course_item_types$course_item_type_category[j]
      }
    for (k in 1:nrow(course_item_types)){
      if (course_items$course_item_type_id[i] == course_item_types$atom_content_type_id[k]) {
        course_items$course_item_type_category[i] = course_item_types$course_item_type_category[k]
      }
    }
    }
  }
  res <- course_items %>% filter(course_item_type_category == "programming") %>%  ungroup() %>%  dplyr::select(n)
  r <- nrow(res)
  if (r > 1){
    res <- sum(res$n)
  } else if (r == 1) {
    res <- res$n[1]
  } else {
    res <- 0
  }
  
    assessment_questions <- fread(paste0(courses_path, '/', course_name, '/', 'assessment_questions.csv')) %>% 
      filter(assessment_question_type_id == 14) %>% nrow()
    # 14 = codeExpression
    # probably better to add them
    if (assessment_questions != 0){
      res <- res + assessment_questions
    }
  return(res)
}
#################### is course with math?  
course_name <- "upravlenie-stoimostju-kompanii"
is_item_math <- function(course_name)
{
  res <- fread(paste0(courses_path, '/', course_name, '/', 'assessment_math_expression_questions.csv')) %>% nrow()  
  assessment_questions <- fread(paste0(courses_path, '/', course_name, '/', 'assessment_questions.csv')) %>% 
      filter(grepl("hasMath=\\\\", assessment_question_prompt)) %>% nrow()
  if (assessment_questions > 0){
      res <- res + assessment_questions
  }
  peer_math <- fread(paste0(courses_path, '/', course_name, '/', 'peer_assignment_submission_schema_parts.csv' )) %>% 
    filter(grepl("math", peer_assignment_submission_schema_part_prompt) 
           | grepl("calculate", peer_assignment_submission_schema_part_prompt)
           | grepl("Рассчитайте", peer_assignment_submission_schema_part_prompt)) %>% nrow()
  if (peer_math > 0){
    res <- res + peer_math
  }
  return(res)
}
is_item_math(course_name)

#####################3
visit_grade <- function()
{
  list <- list.files(path = "/home/vovan/Desktop/visits", full.names = T)
  total <- 0
  staff_act <- 0
  for (l in list) {
    n <- fread(l)
    course_name = str_sub(l, start = nchar(visits_path)+1, end=-5)
    payment0 <- fread(paste0(courses_path, '/', course_name, '/', 'users_courses__certificate_payments.csv')) 
    video_watched <- fread(paste0(watch_path, '/', course_name, '.csv')) 
    questions <- fread(paste0(courses_path, '/', course_name, '/', 'discussion_questions.csv'))  %>% 
      rename("hse_user_id" = grep("user", names(.), value = TRUE)) %>% 
      dplyr::select(-discussion_question_details, -discussion_question_title) %>% 
      dplyr::select(course_id, hse_user_id) %>% group_by(course_id, hse_user_id) %>% 
      summarise(q_n = n()) 
    answers <- fread(paste0(courses_path, '/', course_name, '/', 'discussion_answers.csv'))  %>%  
      rename("hse_user_id" = grep("user", names(.), value = TRUE)) %>% 
      dplyr::select(course_id, hse_user_id, discussion_answer_id) %>% group_by(course_id, hse_user_id) %>% 
      summarise(ans_n = n()) 
    
      # not all members are learners
      membership <- fread(paste0(courses_path, '/', course_name, '/', 'course_memberships.csv')) %>% 
        rename("hse_user_id" = grep("user", names(.), value = TRUE)) %>% 
        mutate(role = case_when(
        course_membership_role == "BROWSER" ~ "learner", 
        course_membership_role == "NOT_ENROLLED" ~ "learner",
        course_membership_role == "PRE_ENROLLED_LEARNER" ~ "learner",
        course_membership_role == "LEARNER" ~ "learner",
        course_membership_role == "COURSE_ASSISTANT" ~ "staff",
        course_membership_role == "TEACHING_STAFF" ~ "staff",
        course_membership_role == "MENTOR" ~ "staff",
        course_membership_role == "INSTRUCTOR" ~ "staff"
      )) 
      staff <- membership %>%  filter(role == "staff") %>% 
        group_by(hse_user_id) %>% arrange(course_membership_ts) %>% slice(1) %>% 
        dplyr::select(hse_user_id, course_membership_ts)
      learners <- membership %>%  filter(role == "learner") %>% 
        group_by(hse_user_id) %>% arrange(course_membership_ts) %>% slice(1) %>% 
        dplyr::select(hse_user_id, course_membership_ts)
      
      
      
    #was there a payment for course or not?
    payment <-  payment0 %>%  rename("hse_user_id" = grep("user", names(.), value = TRUE)) %>% 
      mutate(what_pay = case_when(
      was_payment == "t" ~ "was_payment",
      was_finaid_grant == "t" ~ "was_finaid_grant",
      was_group_sponsored == "t"~ "was_group_sponsored"
    )) %>% mutate(was_payment = case_when(
      was_payment == "t" ~ 1, 
      was_payment == "f" ~ 0), was_finaid_grant = case_when(
        was_finaid_grant == "t" ~ 1, 
        was_finaid_grant == "f" ~ 0),was_group_sponsored = case_when(
          was_group_sponsored == "t" ~ 1, 
          was_group_sponsored == "f" ~ 0)) %>% 
      mutate(was = was_payment + was_finaid_grant + was_group_sponsored)  %>% 
      dplyr::select(-met_payment_condition, -was_payment, -was_finaid_grant, -was_group_sponsored)
      
    
    #add grades
    grades <- fread(paste0(courses_path, '/', course_name, '/', 'course_grades.csv')) %>% 
      rename("hse_user_id" = grep("user", names(.), value = TRUE))  %>% 
      dplyr::select(course_id, hse_user_id, course_passing_state_id, course_grade_overall, course_grade_ts) 
    
    
    ### merge learners
    grades1 <-merge(grades, learners) %>% 
      dplyr::select(course_id, hse_user_id, course_passing_state_id, course_grade_overall, course_grade_ts, course_membership_ts)
    
    # time to merge all datasets: n, grades, payment? watched video
    ### merge grades
    passing_rate <- nrow(grades1 %>% filter(course_passing_state_id != 0)) / nrow(grades1)
    
    data_grades <- merge(n, grades1, all = TRUE) %>% mutate(vis_p = case_when(
      is.na(n) == TRUE ~ 0,
      is.na(n) != TRUE ~ as.double(n)
    ),
    vis_b = case_when(
      is.na(n) == TRUE ~ 0,
      is.na(n) != TRUE ~1
    )) %>% filter(course_passing_state_id != 0) %>% dplyr::select(-n)
    
    data_grades$course_slug <- str_sub(l, start = nchar(visits_path)+1, end=-5)
    
    ### merge forum activity
    data_activity <-  merge(data_grades, questions, all = TRUE)
    data_activity <-  merge(data_activity, answers, all = TRUE) %>% mutate(q_n = case_when(
      is.na(q_n) == TRUE ~ 0,
      is.na(q_n) != TRUE ~ as.double(q_n)
    ),
    ans_n = case_when(
      is.na(ans_n) == TRUE ~ 0,
      is.na(ans_n) != TRUE ~ as.double(ans_n)
    ))
    
    ### merge watched video
    data_watch <- merge(data_activity, video_watched, all = TRUE) %>% mutate(watch_all = case_when(
      is.na(watch_all) == TRUE ~ 0,
      is.na(watch_all) != TRUE ~ as.double(watch_all)
    ),
    watch_unique = case_when(
      is.na(watch_unique) == TRUE ~ 0,
      is.na(watch_unique) != TRUE ~ as.double(watch_unique)
    ))
    data_watch$video_n <- fread(paste0(courses_path, '/', course_name, '/', 'course_items.csv')) %>% 
      filter(course_item_type_id == 1 || course_item_type_id == 101) %>% 
      nrow()
    
    ### merge payment
    if (nrow(payment0) != 0)
    {
      data_pay <- merge(data_watch, payment, all = TRUE) %>% 
      filter(!is.na(course_passing_state_id)) %>% 
        mutate(was_pay = case_when(
        is.na(was) == TRUE ~ 0,
        is.na(was) != TRUE ~ 1
      )) %>% mutate(what_pay = case_when(
        is.na(what_pay) == TRUE ~ "no_pay",
        is.na(what_pay) != TRUE ~ what_pay
      )) %>% dplyr::select(-was)
    }
    else 
    {
      data_pay <- data_watch %>% filter(!is.na(course_passing_state_id))%>% 
        mutate(was_pay = 0, what_pay = "no_pay")
    }
    
    # do course contain programming assignments? if yes = 1, no = 0
    data_pay$is_prog_n = is_item_prog(course_name) 
    
    data_pay <- data_pay %>%   mutate(is_prog_b = case_when(
      is_prog_n == 0 ~ 0,
      is_prog_n != 0 ~ 1
    ))
    
    # do course contain math assignments? if yes = 1, no = 0
    data_pay$is_math_n <- is_item_math(course_name) 
    
    data_pay <- data_pay %>% mutate(is_math_b = case_when(
        is_math_n == 0 ~ 0,
        is_math_n != 0 ~ 1
      ))
    
    data_pay$is_peer_n <- fread(paste0(courses_path, '/', course_name, '/', 'course_items.csv')) %>% 
      filter(course_item_type_id == 104)  %>% nrow()  
    # 104 = peer
    data_pay <- data_pay %>% mutate(is_peer_b = case_when(
      is_peer_n == 0 ~ 0,
      is_peer_n != 0 ~ 1
    ), passing_rate = passing_rate)
    
    # time to merge all data datasets in final table
    if (total == 0){
      total <- data_pay
    }
    else{
      total <- rbind(total, data_pay)
    }
    
    staff_activity_q <- merge(staff, questions) %>% 
      summarise(q_staff = sum(q_n, na.rm = TRUE))
    
    staff_activity_ans <- merge(staff, answers) %>% 
      summarise(ans_staff = sum(ans_n, na.rm = TRUE))
    
    staff_a <- merge(staff_activity_q, staff_activity_ans, all = TRUE) %>% 
      mutate(course_slug = str_sub(l, start = nchar(visits_path)+1, end=-5), 
             student_n = nrow(data_pay), student_vis_mean = mean(data_pay$vis_p),
             vis_learner_p = sum(data_pay$vis_p), vis_learner_b = sum(data_pay$vis_b),
             q_learner = sum(data_pay$q_n), ans_learner =sum(data_pay$ans_n))
    if (staff_act == 0){
      staff_act <- staff_a
    }
    else{
      staff_act <- rbind(staff_act, staff_a)
    }
  }

  total2 <- total %>%  group_by(course_slug) %>% 
    mutate(duration = round(difftime(course_grade_ts, course_membership_ts, units = "days")))
  
  course_ids <- fread("/home/vovan/Desktop/september_2020/data_n.csv", encoding = "UTF-8") %>%  
    distinct(course_name, course_id) %>% filter(!is.na(course_id)) %>% mutate(course_name = case_when(
      course_name == "Jacobi modular forms: 30 ans apr?s" ~ "Jacobi modular forms: 30 ans après",
      course_name != "Jacobi modular forms: 30 ans apr?s" ~ course_name))
  
  fields <- fread("/home/vovan/Desktop/september_2020/course_types.csv", encoding = "UTF-8") %>% dplyr::select(title, lang, field, spec) %>% 
    rename(course_name = title) %>% 
    mutate(spec = case_when(
      spec == "" ~ "IND",
      spec != "" ~ spec
    )) %>% mutate(spec_b = case_when(
      spec == "IND" ~ "IND",
      spec != "IND" ~ "SPEC"
    ))
  
  fields <- merge(fields, course_ids)
  
  students <- merge(total2, fields)
  
  ## merge staff info
  courses <- students %>% 
    distinct(course_slug, passing_rate, spec_b, field, is_prog_n,is_prog_b, is_math_n,  is_math_b, is_peer_n, is_peer_b) %>% 
    merge(., staff_act, all = TRUE) %>% filter(!(is.na(field))) %>% 
    mutate(item_type =(is_math_b + is_prog_b))
  write.csv(courses, file=paste("/home/vovan/Desktop/data/courses.csv", sep = ""), row.names = FALSE)
  
  return(students)
} 

students <- visit_grade()

#3.
##### to check

write.csv(students, file=paste("/home/vovan/Desktop/data/students.csv", sep = ""), row.names = FALSE)

courses <- fread("/home/vovan/Desktop/data/courses.csv")


u <- data.frame(unique(total$course_id), unique(total$course_slug))
u$is <- unique(total$course_id) %in% fields$course_id
u <- filter(u, is == FALSE)
u

# 4. full activity 

names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
for (i in 1:99) {
    name = names$course_slug[i]
    questions <- fread(paste0(courses_path, '/', course_name, '/', 'discussion_questions.csv'))  %>% 
      rename("hse_user_id" = grep("user", names(.), value = TRUE)) %>% 
      dplyr::select(-discussion_question_details, -discussion_question_title) %>% 
      dplyr::select(course_id, hse_user_id) %>% group_by(course_id, hse_user_id) %>% 
      summarise(q_n = n()) 
    answers <- fread(paste0(courses_path, '/', course_name, '/', 'discussion_answers.csv'))  %>%  
      rename("hse_user_id" = grep("user", names(.), value = TRUE)) %>% 
      dplyr::select(course_id, hse_user_id, discussion_answer_id) %>% group_by(course_id, hse_user_id) %>% 
      summarise(ans_n = n()) 
    
    # not all members are learners
    membership <- fread(paste0(courses_path, '/', course_name, '/', 'course_memberships.csv')) %>% 
      rename("hse_user_id" = grep("user", names(.), value = TRUE)) %>% 
      mutate(role = case_when(
        course_membership_role == "BROWSER" ~ "learner", 
        course_membership_role == "NOT_ENROLLED" ~ "learner",
        course_membership_role == "PRE_ENROLLED_LEARNER" ~ "learner",
        course_membership_role == "LEARNER" ~ "learner",
        course_membership_role == "COURSE_ASSISTANT" ~ "staff",
        course_membership_role == "TEACHING_STAFF" ~ "staff",
        course_membership_role == "MENTOR" ~ "staff",
        course_membership_role == "INSTRUCTOR" ~ "staff"
      )) 
    staff <- membership %>%  filter(role == "staff") %>% 
      group_by(hse_user_id) %>% arrange(course_membership_ts) %>% slice(1) %>% 
      dplyr::select(hse_user_id, course_membership_ts)
    learners <- membership %>%  filter(role == "learner") %>% 
      group_by(hse_user_id) %>% arrange(course_membership_ts) %>% slice(1) %>% 
      dplyr::select(hse_user_id, course_membership_ts)
    
  i = i + 1 
}
