# HSE_MOOC_forums_analytics

 [Web-site with all information](https://vladdez.github.io/MOOC/about.html)

There are about one hundred online courses from the Higher School of Economics (HSE) on the Coursera platform. I am studying how students interact on the forums of these courses and how it affects their learning. This report covers 60 courses.

Course data is stored in the "data" folder. Reports in HTML format and report code in Rmd format are stored in the "analyses_code" folder. To view the HTML report, it needs to be downloaded and opened in a browser. The "parser_code" folder contains the code used to create all the variables.

Reports cover the following topics:

  0. **descriptive**
      - important statistics;
  1. **vif**
      - variance inflation factor for different models;

### What affects forum visits?

  1. **visit_courses**
      - average number of students visiting the forum and the average page views;
      - how the course type influences this: whether it includes programming assignments or belongs to a specialization;
  2. **visit_assignments**
      - how often the forum is visited *during the completion* of programming assignments and tests;

### Why does the course type affect forum visits?

  3. **survival**
      - how forum visits are related to course survival;
      - how the course type is related to course survival;
  4. **duration**
      - how course duration affects forum visits;
      - the standard deviation of forum visits depending on the course;
      - how the course type is related to course duration;
  5. **attempts_time**
      - how different assignment types affect the number of attempts;
      - how different assignment types affect the time spent interacting with the assignment;
  6. **Rasch model**
      - how the probability of completing an assignment on the first attempt is related to the assignment type and forum visits during the period between starting the assignment and the first attempt;

### How can moderators influence forum visits by students?

  7. **moderators**
      - how moderator activity on the forum affects student activity;

### Topics not included in the main study

  8. **certification**
      - how forum visits are related to course payment;
      - how payment, forum visits, and the presence of programming assignments on the course are related;
  9. **grade**
      - how forum visits are related to students' grades for the course;

The file Results.drawio visualizes all the relationships considered in the reports (currently without indicating the strength of the relationships).
