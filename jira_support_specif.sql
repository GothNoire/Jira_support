create or replace package jira_exchange_support as

is_debug$i      integer:=0;

-- сформировать данные параметров
function get_jira_param_data(project$c      varchar2 := null --куда создаем задачу (SD, DEV...)
                            ,summary$c      varchar2 := null --Тема задачи
                            ,description$c  varchar2 := null --Описание задачи
                            ,issuetype$c    varchar2 := null --тип задачи, задается "Bug" или "Task", по умолчанию таск
                            ,reporter$c     varchar2 := null --кого назначить автором, если пусто,
                                                             --то автором будет тот чьи логин и пасс используются в авторизации
                            ,assignie$c     varchar2 := null --на кого назначена, если пусто назначается на пользователя по умолчанию 
                                                             --или по правилу в зависимости от компонента
                            ,pc_name$c      varchar2 := null --имя ПК
                            ,components$i   integer  := null --если есть компонента, здесь указываем ее ID
                            ,priority$i     integer  := null -- приоритет
                            ,status$i       integer  := null -- статус
                            ,comment$c      varchar2 := null -- комментарий
                            ,other_params$c varchar2 := null --возможно нужно будет указывать и другие параметры
                          ) return varchar2;

-- обновить заявку в Jira
function update_jira_issue(key_name$c varchar2 := null,
                           data$c varchar2 := null,
                           type_request$i integer := null, -- тип запроса 0-автоматически, 1- GET, 2 - PUT
                           api_method$i integer := jira_consts.c_api_method_issue$i, -- способ обращения к API
                           jql$c varchar2 := null, -- строка поиска для api_method$i = jira_consts.c_api_method_search$i
                           api_method$c varchar2 := null
                           ) return jira_arr;

--создание заявки в Jira
function create_issue (key$c varchar2 := null --куда создаем задачу (SD, DEV...)
                      ,summary$c varchar2 := null --Тема задачи
                      ,description$c varchar2 := null --Комментарий
                      ,issuetype$c varchar2 := jira_consts.c_itype_task$c --тип задачи, задается "Bug" или "Task", по умолчанию таск
                      ,reporter$c varchar2 := null --кого назначить автором, если пусто, 
                                                   --то автором будет тот чьи логин и пасс используются в авторизации
                      ,assignie$c varchar2 := null --на кого назначена, если пусто назначается на пользователя по умолчанию 
                                                   --или по правилу в зависимости от компонента
                      ,pc_name$c varchar2 := null --имя ПК
                      ,components$i integer := null --если есть компонента, здесь указываем ее ID
                      ,other_params$c varchar2 := null --возможно нужно будет указывать и другие параметры
                      ) return jira_arr;