create or replace package body jira_support as

c_name_pack$c constant varchar2(100) := 'jira_support';

--����� �� Jira
url_jira$c        varchar2(1000):= c_data_support.get_const(1530);
--����� ��� �������� �������
-- c_data_support.get_const(21) - ����� ������� ��
url_jira_api$c    varchar2(1000):= 'http://'||c_data_support.get_const(21)||'/https/'||url_jira$c||'/rest/api/2/';
url_search_api$c  varchar2(1000):= 'http://'||c_data_support.get_const(21)||'/https/'||url_jira$c||'/rest/api/2/search?jql='; -- ����� �����
--https ����� �� Jira
url_jira_browse$c varchar2(1000):= 'https://'||url_jira$c||'/browse/';

j_login$c         varchar2(100):= 'admin';
j_pass$c          varchar2(100):= 'admin';

-- ������������ ������ ����������
function get_jira_param_data(project$c      varchar2 := null --���� ������� ������ (SD, DEV...)
                            ,summary$c      varchar2 := null --���� ������
                            ,description$c  varchar2 := null --�����������
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
                          ) return varchar2
is
  debug$n number:=0;
  data$c  varchar2(32767);
  sep$c   varchar2(10):='';
  
procedure set_data( value$c    varchar2:=null )
is
begin
  data$c := data$c||sep$c||value$c;
  sep$c:=',';
end;

begin
  debug$n:=1;
  --����� json ������
--  data$c := '{ "fields": { ';
  data$c:='';
  
  -- ������ SD, DEV
  if project$c is not null then
    set_data('"project": {"key": "'||project$c||'"}');
  end if;

  -- ��� ������, �������� "Bug" ��� "Task", �� ��������� ����
  if issuetype$c is not null then
    set_data('"issuetype": {"name": "'||issuetype$c||'"}');
  end if;
  
  -- ���� ������
  if summary$c is not null then
    set_data('"summary": "'||encoding_support.escape_json(summary$c)||'"');
  end if;
  --��������
  if description$c is not null then
    set_data('"description": "'||encoding_support.escape_json(description$c)||'"');
  end if;
  
  -- �����
  if reporter$c is not null then
    set_data('"reporter": {"name": "'||encoding_support.escape_json(reporter$c)||'"}');
  end if;
  -- ��� ����������
  if pc_name$c is not null then
    set_data('"customfield_14305": "'||encoding_support.escape_json(pc_name$c)||'"');
  end if;
  -- ���������� "��������� ��������"     
  if components$i is not null then
    set_data('"components": [{"id": "'||components$i||'"}]');
  end if;
  
  -- �� ���� ���������
  if assignie$c is not null then
    set_data('"assignee": {"name": "'||encoding_support.escape_json(assignie$c)||'"}');
  end if;
  -- ���������
  if priority$i is not null then
    set_data('"priority": {"id": "'||priority$i||'"}');
  end if;
  -- ������
  if status$i is not null then
    set_data('"status": {"id": "'||status$i||'"}');
  end if;
  -- �����������
  if comment$c is not null then
    set_data('"comment": [{"add": {"body": "'||encoding_support.escape_json(comment$c)||'"}}]');
  end if;
  
  -- ������ ���������
  if other_params$c is not null then
    set_data(other_params$c);
  end if;
       
--  data$c := data$c||'}}';

  if is_debug$i > 0 then
    dbms_output.put_line('-------');
    dbms_output.put_line('get_jira_param_data(): '||data$c);
    dbms_output.put_line('-------');
  end if;

  return data$c;
exception
  when others then 
    raise_application_error(-20001, sqlerrm(sqlcode)||', '||c_name_pack$c||'.get_jira_param_data, debug$n='||debug$n);
end get_jira_param_data;


-- �������� ������ � Jira
function update_jira_issue(key_name$c varchar2 := null,
                           data$c varchar2 := null,
                           type_request$i integer := null, -- ��� ������� 0-�������������, 1- GET, 2 - PUT
                           api_method$i integer := jira_consts.c_api_method_issue$i, -- ������ ��������� � API
                           jql$c varchar2 := null, -- ������ ������ ��� api_method$i = jira_consts.c_api_method_search$i
                           api_method$c varchar2 := null
                          ) return jira_arr
is
  debug$n number := 0;
  dbg_name$c  varchar2(200) := ' '||c_name_pack$c||'.update_jira_issue (debug$n=';
  val$c varchar2(32767) := 'key_name$c='||key_name$c||', '||
                          'data$c='||data$c||', '||
                          'type_request$i='||type_request$i||', '||
                          'api_method$i='||api_method$i||', '||
                          'jql$c='||jql$c||', '||
                          'api_method$c='||api_method$c||
                          ')';
  responce$a jira_arr; -- ����� �������
  status_code$c varchar2(1000); -- ������ ���������� �������
  request_method$c varchar2(10) := 'POST';
  the_data$c varchar2(32767) := data$c;
  size$i integer := 0;
  line$c varchar2(32767);
  req$r  utl_http.req;
  resp$r utl_http.resp;
  err$c varchar2(1000);
  err$e exception;
begin
  debug$n := 1; -- ��������� ������� ���������
  if (api_method$i = jira_consts.c_api_method_search$i and jql$c is null) then
    err$c := '��� ������ ����� ������ ���� �������� �������� ������!';
    raise err$e;
  end if; 
  if (api_method$i = jira_consts.c_api_method_other$i and api_method$c is null) then
    err$c := '���������� ������� �����!';
    raise err$e;
  end if;

  debug$n := 2;
  if nvl(api_method$i, jira_consts.c_api_method_issue$i) in (jira_consts.c_api_method_issue$i -- ����������� ��������� � API (�� ������)
                                                            ,jira_consts.c_api_method_other$i) --����������� ��������� � API (������ API ������)
  then 
    if (nvl(type_request$i, 0) = 1) then
      request_method$c := 'GET'; -- ������ ������
    elsif (type_request$i = 2) then
      request_method$c := 'POST';
    elsif (key_name$c is not null) then
      request_method$c := 'PUT';
    end if;

    if (nvl(type_request$i, 0) = 0) then
      if (key_name$c is not null) then
        the_data$c := '{ "update": { '||data$c||'}}';
      else
        the_data$c := '{ "fields": { '||data$c||'}}';
      end if;
    end if;
  elsif (api_method$i = jira_consts.c_api_method_search$i) then -- ��������� � API ������
    request_method$c := 'GET';
    the_data$c := null;
  end if;

  debug$n := 3;-- �������� �������
  utl_http.set_body_charset('utf-8');

  debug$n := 4;
  utl_http.set_transfer_timeout(60);

  debug$n := 5;
  if (nvl(api_method$i, jira_consts.c_api_method_issue$i) = jira_consts.c_api_method_issue$i) then -- ����������� ��������� � API (�� ������)
    req$r := utl_http.begin_request(url_jira_api$c||'issue/'||key_name$c, request_method$c, 'HTTP/1.1');
  elsif (api_method$i = jira_consts.c_api_method_search$i) then -- ��������� � API ������
    req$r := utl_http.begin_request(url_search_api$c||jql$c, request_method$c, 'HTTP/1.1');
  end if;

  debug$n := 6; -- ���������� ������ ������ ��� POST � PUT ��������
  size$i := nvl(length(encoding_support.utf8(the_data$c)), 0);

  debug$n := 7; -- ������������� ���������
  utl_http.set_authentication(req$r, j_login$c, j_pass$c);
  utl_http.set_header(req$r, 'Content-Type', 'application/json; charset=utf-8');
  utl_http.set_header(req$r, 'Content-Length', size$i);
  
  debug$n := 8; -- ������ post-������ ��� POST � PUT ��������
  utl_http.write_text(req$r, the_data$c);

  debug$n := 9; -- �������� ������� � �������� ������
  resp$r := utl_http.get_response(req$r);

  debug$n := 10; -- ��������� � ������ (����� ������ ��� �����������)
  status_code$c := to_char(resp$r.status_code);

  debug$n := 11; -- ������ ���� ������ � ������
  responce$a.delete;
  begin
    loop
      debug$n := 12;
      utl_http.read_text(resp$r, line$c, 2000);
      if is_debug$i > 0 then
        output(line$c);
      end if;
      responce$a(responce$a.count+1):=line$c;
    end loop;
  exception
    when utl_http.end_of_body then 
      utl_http.end_response(resp$r);
  end;

  debug$n := 13; -- ������� ����
  utl_http.clear_cookies();

  return responce$a;
exception
  when err$e then
    raise_application_error(-20002, err$c||dbg_name$c||debug$n||', '||val$c);
  when others then 
    raise_application_error(-20001, sqlerrm(sqlcode)||dbg_name$c||debug$n||', '||val$c);
end update_jira_issue;


--�������� ������ � Jira
function create_issue (key$c varchar2 := null --���� ������� ������ (SD, DEV...)
                      ,summary$c varchar2 := null --���� ������
                      ,description$c varchar2 := null --�������� ������
                      ,issuetype$c varchar2 := jira_consts.c_itype_task$c --��� ������, �������� "Bug" ��� "Task", �� ��������� ����
                      ,reporter$c varchar2 := null --���� ��������� �������, ���� �����, 
                                                   --�� ������� ����� ��� ��� ����� � ���� ������������ � �����������
                      ,assignie$c varchar2 := null --�� ���� ���������, ���� ����� ����������� �� ������������ �� ��������� 
                                                   --��� �� ������� � ����������� �� ����������
                      ,pc_name$c varchar2 := null --��� ��
                      ,components$i integer := null --���� ���� ����������, ����� ��������� �� ID
                      ,other_params$c varchar2 := null --�������� ����� ����� ��������� � ������ ���������
                      ) return jira_arr
is
  data$c varchar2(32767); --������ ��� �������� � �������(��� POST � PUT ��������)
  responce$a jira_arr; --����� �������
  debug$n number;
begin
  debug$n:=1;
  data$c:=get_jira_param_data(
         project$c      => key$c          --���� ������� ������ (SD, DEV...)
        ,summary$c      => summary$c      --���� ������
        ,description$c  => description$c  --�������� ������
        ,issuetype$c    => issuetype$c    --��� ������, �������� "Bug" ��� "Task", �� ��������� ����
        ,reporter$c     => reporter$c     --���� ��������� �������, ���� �����, 
                                          --�� ������� ����� ��� ��� ����� � ���� ������������ � �����������
        ,assignie$c     => assignie$c     --�� ���� ���������, ���� ����� ����������� �� ������������ �� ��������� 
                                          --��� �� ������� � ����������� �� ����������
        ,pc_name$c      => pc_name$c      --��� ��
        ,components$i   => components$i   --���� ���� ����������, ����� ��������� �� ID
        ,other_params$c => other_params$c --�������� ����� ����� ��������� � ������ ���������, ������� ���������� ��� ��� ����
        );

  -- ������� ������ � Jira         
  debug$n:=2;
  responce$a:= update_jira_issue(null, data$c );
  
  return responce$a;
exception
  when others then 
    raise_application_error(-20000, '['||sqlerrm(sqlcode)||' '||c_name_pack$c||'.create_issue debug$n='||debug$n
      ||' data$c='||substr(data$c,0,3000)||']');
end create_issue;

-- ��������� ������ �� Jira         
function get_jira_issue(key_name$c   varchar2:=null
                        ) return clob
is
  responce$a  jira_arr; --����� �������
  json$cl     clob:=empty_clob;
  debug$n     number:=0;
begin
  debug$n:=1;
  responce$a:= update_jira_issue(key_name$c, null, 1);
  
  debug$n:=2;
  dbms_lob.createtemporary(json$cl, true);
  dbms_lob.open(json$cl, dbms_lob.lob_readwrite);

  debug$n := 3;
  if responce$a.count>0 then
    for rec in responce$a.first..responce$a.last
    loop
      debug$n := 4;
      dbms_lob.append(json$cl, responce$a(rec));
    end loop;
  end if;
    
  return json$cl;
exception
  when others then 
    raise_application_error(-20001, sqlerrm(sqlcode)||', '||c_name_pack$c||'.get_jira_issue, debug$n='||debug$n
      ||' key_name$c='||key_name$c);
end get_jira_issue;    

-- �������� �����
procedure add_link(key_name$c varchar2:=null
                  ,link_key_name$c varchar2:=null
                  ,link_type$c varchar2:=jira_consts.c_link_connect$c
                  )
is
  data$c      varchar2(1000);
  responce$a  jira_arr; --����� �������
  message$c varchar2(4000);
  status$i integer;
  null_param$e exception;
begin
  if key_name$c is null or link_key_name$c is null or link_type$c is null then
    raise null_param$e;
  end if;

  data$c:='{"outwardIssue":{"key":"'key_name$c'"},'
          '"inwardIssue": {"key":"'||link_key_name$c'"},'
          '"type": {"name":"'||link_type$c'"}'
          '}"';
  
  responce$a:= update_jira_issue(data$c => data$c
                                ,type_request$i => 2 --POST
                                ,api_method$i => jira_consts.c_api_method_other$i
                                ,api_method$c => 'issueLink/');
  
exception
  when null_param$e then
    raise_application_error(-20001, '������ ��������� � jira_exchange_support.add_link');
  when others then
    raise_application_error(-20001, dbms_utility.format_error_stack  dbms_utility.format_error_backtrace ||' jira_exchange_support.add_link'||val$c);
end add_link;

end jira_support;