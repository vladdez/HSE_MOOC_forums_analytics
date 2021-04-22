library(stringr)
library(janitor)
library(lubridate)
library(microbenchmark)
courses_path = "/home/vovan/Desktop/september_2020/"
course_name <- "algorithms-on-graphs"

##########################################

names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
visits_path = "/home/vovan/Desktop/visits/"
courses_path = "/home/vovan/Desktop/september_2020/"


# 1. time window analysis - programming



links_in_window_prog <- function(){
  names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
  courses_path = "/home/vovan/Desktop/september_2020/"
  for (i in 1:99) {
    if (names$ready[i] == "done"){
      course_name <- names$course_slug[i] 
      file = paste("/home/vovan/Desktop/quiz_in_timewindow/prog/", course_name, ".csv", sep = "")
      print(course_name)
      if (file.exists(file) != TRUE) {
        programming_submissions <-  fread(paste0(courses_path, course_name, '/', 'programming_submissions.csv')) %>% 
          rename("hse_user_id" = grep("user", names(.), value = TRUE)) 
        if (nrow(programming_submissions) != 0){
          print("data reading ...")
          course_branch_item_programming_assignments <- fread(paste0(courses_path, course_name, '/', 'course_branch_item_programming_assignments.csv')) %>% 
            dplyr::select(programming_assignment_id, course_item_id) 
          
          programming_submissions <- programming_submissions %>% right_join(., course_branch_item_programming_assignments, by = "programming_assignment_id") %>% 
            distinct(programming_submission_id, .keep_all = TRUE)
          
          # student pass an assigment if his score will be higher or equal then passign fraction
          passing_fraction <- fread(paste0(courses_path, course_name, '/', 'programming_assignments.csv')) %>% 
            dplyr::select(programming_assignment_id, programming_assignment_passing_fraction)
          prog_start <- fread(paste0("/home/vovan/Desktop/prog_visit_ts/", course_name, '.csv')) 
          
          print("exclude not passed ...")
          prog_ts <- left_join(programming_submissions, passing_fraction) %>% 
            left_join(., prog_start) %>% 
            group_by(hse_user_id, programming_assignment_id) %>% 
            filter(programming_submission_grading_status != "started")  
          
          rm(programming_submissions)
          rm(prog_start)
          rm(passing_fraction)
          
          print("define window of interaction ...")
          prog_ts2 <- prog_ts %>% 
            # counting score fraction and success by fraction
            mutate(programming_submission_grading_status = dplyr::recode(programming_submission_grading_status, `failed` = 0, `successed` = 1),
                   programming_submission_score2 = ifelse(programming_submission_score == 0, 0, round(programming_submission_score / max(programming_submission_score), digits = 3))) %>% 
            # arrange by time
            group_by(hse_user_id, programming_assignment_id) %>% 
            arrange(programming_submission_created_ts, .by_group = TRUE) %>% 
            summarise(assessment_status = max(programming_submission_grading_status), 
                      attempts = n(), # until success?
                      start = min(first_interaction), end_att = min(programming_submission_created_ts),
                      end = max(programming_submission_created_ts),
                      #comparing score fraction with counting fraction
                      first_attempt = ifelse(programming_submission_grading_status[1] == 0, 0, 
                                             ifelse(programming_submission_score2 < programming_assignment_passing_fraction, 0, 1))
            ) 
          
          # attempts usually are done with aim to increase score, rarely someone fails test
          rm(prog_ts)
          print("upload data about grades ...")
          
          grades <- fread(paste0(courses_path, '/', course_name, '/', 'course_grades.csv')) %>% 
            rename("hse_user_id" = grep("user", names(.), value = TRUE))  %>% 
            dplyr::select(course_id, hse_user_id, course_passing_state_id, course_grade_overall, course_grade_ts) 
          # to extract only those who passed the course
          
          assessment_ts <- left_join(prog_ts2, grades) %>% filter(course_passing_state_id != 0) %>% 
            dplyr::select(-course_passing_state_id, -course_grade_overall, -course_grade_ts) %>% 
            rename(assessment_id = programming_assignment_id) %>% dplyr::select(-course_id)
          rm(grades) 
          rm(prog_ts2)
          rm(course_branch_item_programming_assignments)
          
          # read visit_ts files
          visit_ts <- fread(paste("/home/vovan/Desktop/visit_ts/",  course_name, ".csv", sep = "")) %>% 
            rename(hse_user_id = user_id)  %>% dplyr::select(-course_id,-url)
          
          print("count visits between interaction ...")
    
          
          visits_between <- function(hse_user_id, start, end, visit_ts)
          {
            tmp <- hse_user_id[1]
            visit_ts1 <- visit_ts[which(hse_user_id == tmp)] 
            vis <- vector()
            
            for (i in 1:length(hse_user_id)){
                a <- visit_ts1$server_timestamp %between% c(start[i], end[i])
                vis[i] <- sum(a)
            }
            print(i)
            return(vis)
          }

          ts <- assessment_ts %>% #filter(hse_user_id == "00037e242f5a2d2fe11186483e193b4088ec7c5d" | hse_user_id == "000d5b871d7d0d895a8388066231f44dd964b059") %>% 
            group_by(hse_user_id) %>% 
            mutate(vis_tw = visits_between(hse_user_id, start, end, visit_ts))
          ts1 <- ts %>% group_by(hse_user_id) %>% 
            mutate(vis_before_attempt_tw = visits_between(hse_user_id, start, end_att, visit_ts))
          
          '''
          write.csv(assessment_ts, file=paste("/home/vovan/Desktop/quiz_in_timewindow/prog/assessment_ts.csv", sep = ""), row.names = FALSE)
          assessment_ts <- fread("/home/vovan/Desktop/quiz_in_timewindow/prog/assessment_ts.csv")
          
          ts <- left_jon(assessment_ts, visit_ts1) 
          ts <- assessment_ts  %>% group_by(hse_user_id) %>% 
            mutate(vis_tw = visits_between(hse_user_id, start, end, visits_ts))  %>% 
            mutate(vis_before_attempt_tw = case_when(
            between(server_timestamp, start, end_att) ~ 1,           
            TRUE ~ 0
          )) 
          '''
          
          print("count time of interaction ...")
          ts2 <- ts1 %>% ungroup() %>% mutate(attempt_time = round(difftime(end_att, start, units = "mins")), 
                                assignment_time = round(difftime(end, start, units = "mins"))) %>% 
            dplyr::select(assessment_id, assessment_status, hse_user_id, vis_tw, vis_before_attempt_tw, attempts, first_attempt, attempt_time, assignment_time)
          
          ts3 <- ts2 %>% filter(attempt_time >= 0, assignment_time >= 0)
          write.csv(ts3, file=paste("/home/vovan/Desktop/quiz_in_timewindow/prog/", course_name, ".csv", sep = ""), row.names = FALSE)
          
        }
      }
    }
  }
}

links_in_window_prog()

# 2. time window anlysis - final
## assessment_action is only for quizzes

links_in_window <- function(){
  names <- fread("/home/vovan/PycharmProjects/lurkers_coursera/names.csv")
  courses_path = "/home/vovan/Desktop/september_2020/"
  for (i in 1:99) {
    if (names$ready[i] == "done"){
      course_name <- names$course_slug[i] 
      file = paste("/home/vovan/Desktop/quiz_in_timewindow/", course_name, ".csv", sep = "")
      if (file.exists(file) != TRUE){
        print(course_name)
        # remove all in-video quizzes
        assessment_types <-  fread(paste0(courses_path, course_name, '/', 'assessment_types.csv'))
        assessments <-  fread(paste0(courses_path, course_name, '/', 'assessments.csv')) %>% merge(., assessment_types) %>% 
          filter(!is.na(assessment_passing_fraction)) %>% dplyr::select(assessment_id, assessment_passing_fraction,    
                                                                        assessment_feedback_configuration, assessment_type_desc)
        
        assessment_actions <-  fread(paste0(courses_path, course_name, '/', 'assessment_actions.csv')) %>% dplyr::select((-guest_user_id)) %>% 
          rename("hse_user_id" = grep("user", names(.), value = TRUE))  %>% 
          dplyr::select(assessment_id, hse_user_id, assessment_action_id, assessment_action_start_ts, assessment_action_ts) %>% 
          right_join(., assessments) %>% filter(!is.na(hse_user_id))
        
        
        
        if (file.exists(paste("/home/vovan/Desktop/visit_ts/",  course_name, ".csv", sep = "")) == TRUE ) {
          ## 1  
          #  to get the assessment_action_ids of assessment quizzes and hse_user
          
          print("upload grades")
          assessment_responses <-  fread(paste0(courses_path, course_name, '/', 'assessment_responses.csv')) %>% 
            dplyr::select(assessment_action_id, assessment_response_score, assessment_id) %>% 
            distinct(assessment_action_id, .keep_all = TRUE)
          
          grades <- fread(paste0(courses_path, '/', course_name, '/', 'course_grades.csv')) %>% 
            rename("hse_user_id" = grep("user", names(.), value = TRUE))  %>% 
            dplyr::select(course_id, hse_user_id, course_passing_state_id, course_grade_overall, course_grade_ts) 
          # to extract only those who passed the course
          
          all <- left_join(assessment_responses, assessment_actions) %>% 
            mutate(assessment_response_score =  ifelse(assessment_response_score < assessment_passing_fraction, 0, 1)) %>% 
            filter(!is.na(assessment_response_score)) %>% 
            dplyr::select(hse_user_id, assessment_id, assessment_response_score, assessment_action_id, assessment_action_ts, assessment_action_start_ts)
          
          # to get attempts for quizzes and their time
          print("count attempt for quizzes")
          all2 <- all  %>% 
            group_by(hse_user_id, assessment_id) %>% arrange(assessment_action_ts, .by_group = TRUE) %>% 
            summarise(assessment_status = max(assessment_response_score, na = TRUE), 
                      attempts = n(),  
                      start = min(assessment_action_start_ts), end = max(assessment_action_ts), 
                      end_att = min(assessment_action_ts), 
                      first_attempt = assessment_response_score[1])
            # join id with attempts and count their numbers, find time stamp for start and for end
          # assessment_response_score == 0 means that this assessment was failed
          # assessment_status - was this assessment passed (1) or not (0)
          # attempts - how many attempts (0 - correct after the first attempt)
          
          assessment_ts <- left_join(all2, grades) %>% filter(course_passing_state_id != 0) %>% 
            dplyr::select(-course_passing_state_id, -course_grade_overall, -course_grade_ts)
          # filter only those who passed the course
          
          visit_ts <- fread(paste("/home/vovan/Desktop/visit_ts/",  course_name, ".csv", sep = "")) %>% 
            rename(hse_user_id = user_id)  %>% dplyr::select(-course_id)
          visit_ts$url <- 1:nrow(visit_ts)
          # read visit_ts files
          # remove everything to avoid crash
          rm(all)
          rm(all2)
          rm(assessment_actions)
          rm(assessment_responses)
          rm(grades)
          
          
          ts <- left_join(assessment_ts, visit_ts) 
          
          ts1 <- ts %>% mutate(vis_tw = case_when(
            between(server_timestamp, start, end) ~ 1, 
            TRUE ~ 0
          ))%>% mutate(vis_before_attempt_tw = case_when(
            between(server_timestamp, start, end_att) ~ 1,           
            TRUE ~ 0
          )) 
          
          ts2 <- ts1%>%  dplyr::select(-server_timestamp) %>% group_by(hse_user_id, assessment_id) %>% 
            mutate(vis_tw = sum(vis_tw), vis_before_attempt_tw = sum(vis_before_attempt_tw)) %>% 
            slice(1) %>% mutate(attempt_time = round(difftime(end_att, start, units = "mins")), 
                                assignment_time = round(difftime(end, start, units = "mins"))) %>% 
            dplyr::select(assessment_id, assessment_status, hse_user_id, vis_tw, vis_before_attempt_tw, attempts, first_attempt, attempt_time, assignment_time)
          
          ts3 <- ts2 %>% filter(attempt_time >= 0, assignment_time >= 0) %>% mutate(attempt_time = as.integer(attempt_time), assignment_time = as.integer(assignment_time))
          
          # mark by 1  those links that are between start and end for each assignment for every student
          # count the number of this links, restore attempt (destroyed because of summarize())
          ## in some cases two items of the same person may obtain the same huge number of forum visits
          ## it is quite legit because students could start and postpone several assessments for months and finish almost simultaneously 
          rm(assessment_ts)
          rm(ts)
          # 3.  here is the join with prog_ts
          
          
          # tables to know the name  and type of assignment
          course_items <- fread(paste0(courses_path, '/', course_name, '/', 'course_items.csv')) %>% 
            mutate(course_item_type_id = dplyr::recode(course_item_type_id, `10` = 111L))
          course_branch_item_assessments <- fread(paste0(courses_path, '/', course_name, '/', 'course_branch_item_assessments.csv'))
          c1<- left_join(course_branch_item_assessments, course_items) %>% 
            dplyr::select(assessment_id, course_item_name, course_item_id, course_item_type_id) %>% 
            filter(!is.na(course_item_name)) 
          
          # to get assessment types and names for programming assignments
          course_item_programming_assignments <- fread(paste0(courses_path, '/', course_name, '/', 'course_item_programming_assignments.csv')) %>% 
            rename(assessment_id = programming_assignment_id)
          
          if (nrow(course_item_programming_assignments) != 0){
            ts_prog <- fread(paste0("/home/vovan/Desktop/quiz_in_timewindow/prog/", course_name, ".csv"))
            ts3 <- rbind(ts3, ts_prog)
            c2 <- left_join(course_item_programming_assignments, course_items) %>% 
              dplyr::select(assessment_id, course_item_name, course_item_id, course_item_type_id)
            
            c1 <- rbind(c1, c2)
          }
          
          course_item_types <- fread(paste0(courses_path, '/', course_name, '/', 'course_item_types.csv')) %>% 
            dplyr::select(atom_content_type_id, course_item_type_desc) %>% 
            rename(course_item_type_id = atom_content_type_id) %>% filter(!is.na(course_item_type_id)) %>% 
            distinct(course_item_type_id, .keep_all = TRUE)
          
          if (i == 21 || i == 53 || i == 35) {
            
            print("CODE EXPRESSSION check")
            print(course_name)
            c_corr0 <- semi_join(c1, ts3, by = "assessment_id")  %>% distinct(assessment_id, .keep_all = TRUE)
            
            #check quizzes with code expressions
            assessment_questions <- fread(paste0(courses_path, '/', course_name, '/', 'assessment_questions.csv')) %>% 
              filter(assessment_question_type_id == 14) %>% dplyr::select(assessment_question_id, assessment_question_type_id)
            assessment_assessments_questions <-  fread(paste0(courses_path, course_name, '/', 'assessment_assessments_questions.csv')) %>% 
              dplyr::select(assessment_question_id, assessment_id)
            code_exp <- left_join(assessment_questions, assessment_assessments_questions) %>% group_by(assessment_id) %>% slice(1)
            
            c_corr <- left_join(c_corr0, code_exp) %>% mutate(course_item_type_id = case_when(
              assessment_question_type_id == "14" ~ as.integer(111),
              TRUE ~ course_item_type_id
              )) %>% dplyr::select(-assessment_question_id, -assessment_question_type_id)
          
          } else {
            c_corr <- semi_join(c1, ts3, by = "assessment_id")  %>% distinct(assessment_id, .keep_all = TRUE)
          }
          
          ts2 <- inner_join(ts3, c_corr, by = "assessment_id") %>% mutate(course_name = course_name) 
          ts3 <- inner_join(ts2, course_item_types)
          
          write.csv(ts3, file=paste("/home/vovan/Desktop/quiz_in_timewindow/", course_name, ".csv", sep = ""), row.names = FALSE)
          
          # remove everything to avoid crash
          rm(ts3)
          rm(ts1)
          rm(ts2)
          rm(visit_ts)
          rm(programming_submissions)
          rm(prog_ts1)
          rm(prog_ts2)
        }
      }
    }
    print (i)
  }
  q <- list.files(path = "/home/vovan/Desktop/quiz_in_timewindow", full.names = TRUE,  pattern=".csv")
  q1 <- lapply(q, fread)
  tw <- data.table::rbindlist(q1, fill=TRUE) %>% 
    mutate(course_item_type_desc = dplyr::recode(course_item_type_desc, `programming assignment` = "programming", `exam` = "quiz")) %>% 
    mutate(course_name = dplyr::recode(course_name, `discrete-maths` = "discrete-math-and-analyzing-social-graphs")) 
  

  write.csv(tw, file=paste("/home/vovan/Desktop/data/assignments.csv", sep = ""), row.names = FALSE)
  # чтобы он еще архив сам создавал
  return(tw)
}

tw <- links_in_window()



# merge with course_item_id ---> is_prog
# check anomalies in attempts
#rbind everyting 
