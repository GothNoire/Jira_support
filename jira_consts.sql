-- Способы обращения к API Jira
create or replace package jira_consts
c_api_method_issue$i       constant integer := 1; -- стандартное обращение к API (создание задачи или получение информации по задачи)
c_api_method_search$i      constant integer := 2; -- обращение к API поиска (поиск задач по фильтру)
c_api_method_other$i       constant integer := 3; -- стандартное обращение к API (другие API методы)

-- Типы задач
c_itype_task$c               constant varchar2(10) := 'Task'; -- Задача
c_itype_bug$c                constant varchar2(10) := 'Bug'; -- Ошибка