-- ������� ��������� � API Jira
create or replace package jira_consts
c_api_method_issue$i       constant integer := 1; -- ����������� ��������� � API (�������� ������ ��� ��������� ���������� �� ������)
c_api_method_search$i      constant integer := 2; -- ��������� � API ������ (����� ����� �� �������)
c_api_method_other$i       constant integer := 3; -- ����������� ��������� � API (������ API ������)

-- ���� �����
c_itype_task$c               constant varchar2(10) := 'Task'; -- ������
c_itype_bug$c                constant varchar2(10) := 'Bug'; -- ������

--���� ������ issueLinkType, ���� name
c_link_connect$c constant varchar2(20) := '������';
end jira_consts;