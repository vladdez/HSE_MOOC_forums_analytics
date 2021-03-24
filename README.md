# HSE_MOOC_forums_analytics

На платформе Coursera есть около ста онлайн-курсов от НИУ ВШЭ. Я занимаюсь изучением того, как студенты общаются на форумах этих курсов и как это влияет на их обучение. Здесь рассматриваются 60 курсов. 

Данные о курсах хранятся в папке data. В папке analyses_code хранятся отчеты в формате html и код отчетов в формате Rmd. Чтобы увидеть html отчет его нужно скачать и открыть в браузере. В папке parser_code хранится код с помощью, которого создавались все переменные.

Чему посвящены отчеты:

### Что влияет на посещение форума?

  1. **visit_courses**
      - сколько студентов в среднем посещают форум и каково среднее посещение страниц;
      - как на это влияет тип курса: есть в нем задания по по программированию, входит ли он в специализацию;
  2. **visit_assignments**
      - сколько раз посещают форум *во время выполнения* заданий по программированию и во время выполнения тестов;
            
### Почему тип курса влияет на посещение форума?

  3. **survival**
      - как связаны посещение форума на курсе и выживаемость на курсе;
      - как связаны тип курса и выживаемость на курсе;
  4. **duration**
      - как длительность прохождения курса влияет на посещение форума;
      - каково стандартное отклонение у посещения форума в зависимости от курса;
      - как связаны тип курса и длительность прохождения курса;
  5. **attempts_time**
      - Как разные типы заданий влияют на количество попыток?
      - Как разные типы заданий влияют на время взаимодействия с заданием?
  6. **Rasсh model**
      - как вероятность выполнить задание с первой попытки связана с посещением форума в промежуток между началом выполнения задания и первой попыткой;
      - как число попыток при выполнения задания связано с посещением форума во время выполнения задания;
 
 ### Как модераторы могут влиять на посещение форума студентами?  
 
  7. **moderators**
      - как тип курса (с программированием/без программирования) влияет на посещение форума;
      - как активность модераторов на форуме влияет на активность студентов;

 
### Темы, которые не вошли в основное исследование
  
  8. **certification**
      - как связано посещение форума с оплатой курса:
      - как связаны оплата курса, посещение форума и есть ли на курсе задания по программированию;
  9. **grade**
      - как посещение форума связана с оценкой студентов за курс;




Файл Results.drawio визуализирует все связи рассмотренные во всех отчетах (пока без указания силы связи).

