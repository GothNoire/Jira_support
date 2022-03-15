create or replace package jira_support as

is_debug$i      integer:=0;

-- ������������ ������ ����������
function get_jira_param_data(project$c      varchar2 := null --���� ������� ������ (SD, DEV...)
                            ,summary$c      varchar2 := null --���� ������
                            ,description$c  varchar2 := null --�������� ������
                            ,issuetype$c    varchar2 := null --��� ������, �������� "Bug" ��� "Task", �� ��������� ����
                            ,reporter$c     varchar2 := null --���� ��������� �������, ���� �����,
                                                             --�� ������� ����� ��� ��� ����� � ���� ������������ � �����������
                            ,assignie$c     varchar2 := null --�� ���� ���������, ���� ����� ����������� �� ������������ �� ��������� 
                                                             --��� �� ������� � ����������� �� ����������
                            ,pc_name$c      varchar2 := null --��� ��
                            ,components$i   integer  := null --���� ���� ����������, ����� ��������� �� ID
                            ,priority$i     integer  := null -- ���������
                            ,status$i       integer  := null -- ������
                            ,comment$c      varchar2 := null -- �����������
                            ,other_params$c varchar2 := null --�������� ����� ����� ��������� � ������ ���������
                          ) return varchar2;

-- �������� ������ � Jira
function update_jira_issue(key_name$c varchar2 := null,
                           data$c varchar2 := null,
                           type_request$i integer := null, -- ��� ������� 0-�������������, 1- GET, 2 - PUT
                           api_method$i integer := jira_consts.c_api_method_issue$i, -- ������ ��������� � API
                           jql$c varchar2 := null, -- ������ ������ ��� api_method$i = jira_consts.c_api_method_search$i
                           api_method$c varchar2 := null
                           ) return jira_arr;

--�������� ������ � Jira
function create_issue (key$c varchar2 := null --���� ������� ������ (SD, DEV...)
                      ,summary$c varchar2 := null --���� ������
                      ,description$c varchar2 := null --�����������
                      ,issuetype$c varchar2 := jira_consts.c_itype_task$c --��� ������, �������� "Bug" ��� "Task", �� ��������� ����
                      ,reporter$c varchar2 := null --���� ��������� �������, ���� �����, 
                                                   --�� ������� ����� ��� ��� ����� � ���� ������������ � �����������
                      ,assignie$c varchar2 := null --�� ���� ���������, ���� ����� ����������� �� ������������ �� ��������� 
                                                   --��� �� ������� � ����������� �� ����������
                      ,pc_name$c varchar2 := null --��� ��
                      ,components$i integer := null --���� ���� ����������, ����� ��������� �� ID
                      ,other_params$c varchar2 := null --�������� ����� ����� ��������� � ������ ���������
                      ) return jira_arr;

-- ��������� ������ �� Jira         
function get_jira_issue(key_name$c   varchar2:=null
                        ) return clob;

-- �������� �����
procedure add_link(key_name$c varchar2:=null
                  ,link_key_name$c varchar2:=null
                  ,link_type$c varchar2:=jira_consts.c_link_connect$c
                  );

end jira_support;

